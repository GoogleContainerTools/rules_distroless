"https://wiki.debian.org/DebianRepository"

load(":nested_dict.bzl", "nested_dict")
load(":version_constraint.bzl", "version_constraint")

def _fetch_package_index(rctx, url, dist, comp, arch):
    # See https://linux.die.net/man/1/xz , https://linux.die.net/man/1/gzip , and https://linux.die.net/man/1/bzip2
    #  --keep       -> keep the original file (Bazel might be still committing the output to the cache)
    #  --force      -> overwrite the output if it exists
    #  --decompress -> decompress
    # Order of these matter, we want to try the one that is most likely first.
    supported_extensions = {
        ".xz": ["xz", "--decompress", "--keep", "--force"],
        ".gz": ["gzip", "--decompress", "--keep", "--force"],
        ".bz2": ["bzip2", "--decompress", "--keep", "--force"],
        "": None,
    }

    failed_attempts = []

    for ext, cmd in supported_extensions.items():
        index = "Packages"
        index_full = "{}{}".format(index, ext) if ext else index

        output = "{dist}/{comp}/{arch}/{index}".format(
            dist = dist,
            comp = comp,
            arch = arch,
            index = index,
        )
        output_full = "{}{}".format(output, ext) if ext else output

        index_url = "{url}/dists/{dist}/{comp}/binary-{arch}/{index_full}".format(
            url = url,
            dist = dist,
            comp = comp,
            arch = arch,
            index_full = index_full,
        )

        download = rctx.download(
            url = index_url,
            output = output_full,
            allow_fail = True,
        )

        if not download.success:
            reason = "Download failed. See warning above for details."
            failed_attempts.append((index_url, reason))
            continue

        if cmd == None:
            # index is already decompressed
            break

        decompress_cmd = cmd + [output_full]
        decompress_res = rctx.execute(decompress_cmd)

        if decompress_res.return_code == 0:
            break

        reason = "'{cmd}' returned a non-zero exit code: {return_code}"
        reason += "\n\n{stderr}\n{stdout}"
        reason = reason.format(
            cmd = decompress_cmd,
            return_code = decompress_res.return_code,
            stderr = decompress_res.stderr,
            stdout = decompress_res.stdout,
        )

        failed_attempts.append((index_url, reason))

    if len(failed_attempts) == len(supported_extensions):
        attempt_messages = [
            "\n  * '{}' FAILED:\n\n  {}".format(url, reason)
            for url, reason in failed_attempts
        ]

        fail("Failed to fetch packages index:\n" + "\n".join(attempt_messages))

    return rctx.read(output)

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
    state.packages.set(
        keys = (package["Architecture"], package["Package"], package["Version"]),
        value = package,
    )

    # https://www.debian.org/doc/debian-policy/ch-relationships.html#virtual-packages-provides
    if "Provides" in package:
        provides = version_constraint.parse_dep(package["Provides"])

        state.virtual_packages.add(
            keys = (package["Architecture"], provides["name"]),
            value = (provides, package),
        )

def _new(rctx, sources, archs):
    state = struct(
        packages = nested_dict.new(),
        virtual_packages = nested_dict.new(),
    )

    for arch in archs:
        for (url, dist, comp) in sources:
            # We assume that `url` does not contain a trailing forward slash when passing to
            # functions below. If one is present, remove it. Some HTTP servers do not handle
            # redirects properly when a path contains "//"
            # (ie. https://mymirror.com/ubuntu//dists/noble/stable/... may return a 404
            # on misconfigured HTTP servers)
            url = url.rstrip("/")

            index = "{}/{} for {}".format(dist, comp, arch)

            rctx.report_progress("Fetching package index: %s" % index)
            output = _fetch_package_index(rctx, url, dist, comp, arch)

            rctx.report_progress("Parsing package index: %s" % index)
            _parse_repository(state, output, url)

    return struct(
        package_versions = lambda arch, name: state.packages.get((arch, name), {}).keys(),
        virtual_packages = lambda arch, name: state.virtual_packages.get((arch, name), []),
        package = lambda arch, name, version: state.packages.get((arch, name, version)),
    )

deb_repository = struct(
    new = _new,
)

# TESTONLY: DO NOT DEPEND ON THIS
def _create_test_only():
    state = struct(
        packages = nested_dict.new(),
        virtual_packages = nested_dict.new(),
    )

    return struct(
        package_versions = lambda arch, name: state.packages.get((arch, name), {}).keys(),
        virtual_packages = lambda arch, name: state.virtual_packages.get((arch, name), []),
        package = lambda arch, name, version: state.packages.get((arch, name, version)),
        parse_repository = lambda contents: _parse_repository(state, contents, "http://nowhere"),
        packages = state.packages,
        reset = lambda: state.packages.clear(),
    )

DO_NOT_DEPEND_ON_THIS_TEST_ONLY = struct(
    new = _create_test_only,
)
