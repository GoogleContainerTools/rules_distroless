"https://wiki.debian.org/DebianRepository"

load(":util.bzl", "util")
load(":version_constraint.bzl", "version_constraint")

def _fetch_package_index(rctx, url, dist, comp, arch, integrity):
    target_triple = "{dist}/{comp}/{arch}".format(dist = dist, comp = comp, arch = arch)

    # See https://linux.die.net/man/1/xz , https://linux.die.net/man/1/gzip , and https://linux.die.net/man/1/bzip2
    #  --keep       -> keep the original file (Bazel might be still committing the output to the cache)
    #  --force      -> overwrite the output if it exists
    #  --decompress -> decompress
    # Order of these matter, we want to try the one that is most likely first.
    supported_extensions = {
        ".xz": ["xz", "--decompress", "--keep", "--force"],
        ".gz": ["gzip", "--decompress", "--keep", "--force"],
        ".bz2": ["bzip2", "--decompress", "--keep", "--force"],
        "": ["true"],
    }

    failed_attempts = []

    for (ext, cmd) in supported_extensions.items():
        output = "{}/Packages{}".format(target_triple, ext)
        dist_url = "{}/dists/{}/{}/binary-{}/Packages{}".format(url, dist, comp, arch, ext)
        download = rctx.download(
            url = dist_url,
            output = output,
            integrity = integrity,
            allow_fail = True,
        )
        decompress_r = None
        if download.success:
            decompress_r = rctx.execute(cmd + [output])
            if decompress_r.return_code == 0:
                integrity = download.integrity
                break

        failed_attempts.append((dist_url, download, decompress_r))

    if len(failed_attempts) == len(supported_extensions):
        attempt_messages = []
        for (url, download, decompress) in failed_attempts:
            reason = "unknown"
            if not download.success:
                reason = "Download failed. See warning above for details."
            elif decompress.return_code != 0:
                reason = "Decompression failed with non-zero exit code.\n\n{}\n{}".format(decompress.stderr, decompress.stdout)

            attempt_messages.append("""\n*) Failed '{}'\n\n{}""".format(url, reason))

        fail("""
** Tried to download {} different package indices and all failed. 

{}
        """.format(len(failed_attempts), "\n".join(attempt_messages)))

    return ("{}/Packages".format(target_triple), integrity)

def _parse_repository(state, contents, root):
    last_key = ""
    pkg = {}
    for group in contents.split("\n\n"):
        for line in group.split("\n"):
            if line.strip() == "":
                continue
            if line[0] == " ":
                pkg[last_key] += "\n" + line
                continue

            # This allows for (more) graceful parsing of Package metadata (such as X-* attributes)
            # which may contain patterns that are non-standard. This logic is intended to closely follow
            # the Debian team's parser logic:
            # * https://salsa.debian.org/python-debian-team/python-debian/-/blob/master/src/debian/deb822.py?ref_type=heads#L788
            split = line.split(": ", 1)
            key = split[0]
            value = ""

            if len(split) == 2:
                value = split[1]

            if not last_key and len(pkg) == 0 and key != "Package":
                fail("Invalid debian package index format. Expected 'Package' as first key, got '{}'".format(key))

            last_key = key
            pkg[key] = value

        if len(pkg.keys()) != 0:
            pkg["Root"] = root
            _add_package(state, pkg)
            last_key = ""
            pkg = {}

def _add_package(state, package):
    util.set_dict(
        state.packages,
        value = package,
        keys = (package["Architecture"], package["Package"], package["Version"]),
    )

    # https://www.debian.org/doc/debian-policy/ch-relationships.html#virtual-packages-provides
    if "Provides" in package:
        for virtual in version_constraint.parse_depends(package["Provides"]):
            providers = util.get_dict(
                state.virtual_packages,
                (package["Architecture"], virtual["name"]),
                [],
            )

            # If multiple versions of a package expose the same virtual package,
            # we should only keep a single reference for the one with greater
            # version.
            for (i, (provider, provided_version)) in enumerate(providers):
                if package["Package"] == provider["Package"] and (
                    virtual["version"] == provided_version
                ):
                    if version_constraint.relop(
                        package["Version"],
                        provider["Version"],
                        ">>",
                    ):
                        providers[i] = (package, virtual["version"])

                    # Return since we found the same package + version.
                    return

            # Otherwise, first time encountering package.
            providers.append((package, virtual["version"]))
            util.set_dict(
                state.virtual_packages,
                providers,
                (package["Architecture"], virtual["name"]),
            )

def _virtual_packages(state, name, arch):
    return util.get_dict(state.virtual_packages, [arch, name], [])

def _package_versions(state, name, arch):
    return util.get_dict(state.packages, [arch, name], {}).keys()

def _package(state, name, version, arch):
    return util.get_dict(state.packages, keys = (arch, name, version))

def _create(rctx, sources, archs):
    state = struct(
        packages = dict(),
        virtual_packages = dict(),
    )

    for arch in archs:
        for (url, dist, comp) in sources:
            # We assume that `url` does not contain a trailing forward slash when passing to
            # functions below. If one is present, remove it. Some HTTP servers do not handle
            # redirects properly when a path contains "//"
            # (ie. https://mymirror.com/ubuntu//dists/noble/stable/... may return a 404
            # on misconfigured HTTP servers)
            url = url.rstrip("/")

            rctx.report_progress("Fetching package index: {}/{} for {}".format(dist, comp, arch))
            (output, _) = _fetch_package_index(rctx, url, dist, comp, arch, "")

            # TODO: this is expensive to perform.
            rctx.report_progress("Parsing package index: {}/{} for {}".format(dist, comp, arch))
            _parse_repository(state, rctx.read(output), url)

    return struct(
        package_versions = lambda **kwargs: _package_versions(state, **kwargs),
        virtual_packages = lambda **kwargs: _virtual_packages(state, **kwargs),
        package = lambda **kwargs: _package(state, **kwargs),
    )

deb_repository = struct(
    new = _create,
)

# TESTONLY: DO NOT DEPEND ON THIS
def _create_test_only():
    state = struct(
        packages = dict(),
        virtual_packages = dict(),
    )

    def reset():
        state.packages.clear()
        state.virtual_packages.clear()

    return struct(
        package_versions = lambda **kwargs: _package_versions(state, **kwargs),
        virtual_packages = lambda **kwargs: _virtual_packages(state, **kwargs),
        package = lambda **kwargs: _package(state, **kwargs),
        parse_repository = lambda contents: _parse_repository(state, contents, "http://nowhere"),
        packages = state.packages,
        reset = reset,
    )

DO_NOT_DEPEND_ON_THIS_TEST_ONLY = struct(
    new = _create_test_only,
)
