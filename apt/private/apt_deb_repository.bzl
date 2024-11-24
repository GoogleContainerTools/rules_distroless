"https://wiki.debian.org/DebianRepository"

load("@bazel_skylib//lib:paths.bzl", "paths")
load(":nested_dict.bzl", "nested_dict")
load(":util.bzl", "util")
load(":version_constraint.bzl", "version_constraint")

def _fetch_package_index(rctx, source):
    # See https://linux.die.net/man/1/xz and https://linux.die.net/man/1/gzip
    #  --keep       -> keep the original file (Bazel might be still committing the output to the cache)
    #  --force      -> overwrite the output if it exists
    #  --decompress -> decompress
    supported_extensions = {
        "xz": ["xz", "--decompress", "--keep", "--force"],
        "gz": ["gzip", "--decompress", "--keep", "--force"],
        "": None,
    }

    failed_attempts = []

    for ext, cmd in supported_extensions.items():
        index_url = source.index_url(ext)
        output_full = source.output_full(ext)

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

    return rctx.read(source.output)

def _make_file_url(pkg, source):
    filename = pkg["Filename"]

    invalid_filename = not paths.is_normalized(
        filename,
        look_for_same_level_references = True,
    )

    if invalid_filename:
        # NOTE:
        # Although the Debian repo spec for 'Filename' (see
        # https://wiki.debian.org/DebianRepository/Format#Filename) clearly
        # says that 'Filename' should be relative to the base directory of the
        # repo and should be in canonical form (i.e. without '.' or '..') there
        # are cases where this is not honored.
        #
        # In those cases we try to work around this by assuming 'Filename' is
        # relative to the sources.list "index path" (e.g. directory/ for flat
        # repos) so we combine them and normalize the new 'Filename' path.
        #
        # Note that, so far, only the NVIDIA CUDA repos needed this workaround
        # so maybe this heuristic will break for other repos that don't conform
        # to the Debian repo spec.
        filename = paths.normalize(paths.join(source.index_path, filename))

    base_url = util.parse_url(source.base_url)
    file_url = "{}://{}{}".format(
        base_url.scheme,
        base_url.host,
        paths.join(base_url.path, filename),
    )

    return file_url, invalid_filename

def _parse_package_index(state, contents, source):
    last_key = ""
    pkg = {}
    total_pkgs = 0
    out_of_spec = []

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
            pkg["File-Url"], invalid_filename = _make_file_url(pkg, source)

            if invalid_filename:
                out_of_spec.append(pkg["Package"])

            _add_package(state, pkg)
            last_key = ""
            pkg = {}
            total_pkgs += 1

    return out_of_spec, total_pkgs

def _add_package(state, package):
    state.packages.set(
        keys = (package["Architecture"], package["Package"], package["Version"]),
        value = package,
    )

    # https://www.debian.org/doc/debian-policy/ch-relationships.html#virtual-packages-provides
    if "Provides" in package:
        provides = version_constraint.parse_provides(package["Provides"])

        state.virtual_packages.add(
            keys = (package["Architecture"], provides["name"]),
            value = (provides["version"], package),
        )

def _new(rctx, manifest):
    state = struct(
        packages = nested_dict.new(),
        virtual_packages = nested_dict.new(),
    )

    for source in manifest.sources:
        index = "%s/%s" % (source.index_path, source.index)

        rctx.report_progress("Fetching package index: %s" % index)
        output = _fetch_package_index(rctx, source)

        rctx.report_progress("Parsing package index: %s" % index)
        out_of_spec, total_pkgs = _parse_package_index(state, output, source)

        if out_of_spec:
            count = len(out_of_spec)
            pct = int(100.0 * count / total_pkgs)
            msg = "Warning: index {} has {} packages ({}%) with invalid 'Filename' fields"
            print(msg.format(index, count, pct))

    return struct(
        package_versions = lambda arch, name: state.packages.get((arch, name), {}).keys(),
        virtual_packages = lambda arch, name: state.virtual_packages.get((arch, name), []),
        package = lambda arch, name, version: state.packages.get((arch, name, version)),
    )

deb_repository = struct(
    new = _new,
    __test__ = struct(
        _fetch_package_index = _fetch_package_index,
        _make_file_url = _make_file_url,
        _parse_package_index = _parse_package_index,
    ),
)
