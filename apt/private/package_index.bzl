"package index"

load("@bazel_skylib//lib:paths.bzl", "paths")
load(":util.bzl", "util")

def _fetch_package_index(rctx, url, arch, dist = None, comp = None, directory = None):
    # TODO: validate mutually exclusive args (dist, comp) VS directory

    # See https://linux.die.net/man/1/xz and https://linux.die.net/man/1/gzip
    #  --keep       -> keep the original file (Bazel might be still committing the output to the cache)
    #  --force      -> overwrite the output if it exists
    #  --decompress -> decompress
    supported_extensions = {
        "xz": ["xz", "--decompress", "--keep", "--force"],
        "gz": ["gzip", "--decompress", "--keep", "--force"],
    }

    failed_attempts = []

    for ext, cmd in supported_extensions.items():
        index = "Packages"
        index_full = "{}.{}".format(index, ext)

        if directory == None:  # canonical repo
            output = "{dist}/{comp}/{arch}/{index}".format(
                dist = dist,
                comp = comp,
                arch = arch,
                index = index,
            )

            index_url = "{url}/dists/{dist}/{comp}/binary-{arch}/{index_full}".format(
                url = url,
                dist = dist,
                comp = comp,
                arch = arch,
                index_full = index_full,
            )
        else:  # flat repo
            output = "{directory}/{arch}/{index}".format(
                directory = directory,
                arch = arch,
                index = index,
            )

            index_url = "{url}/{directory}/{index_full}".format(
                url = url,
                directory = directory,
                index_full = index_full,
            )

        output_full = "{}.{}".format(output, ext)

        download = rctx.download(
            url = index_url,
            output = output_full,
            allow_fail = True,
        )
        decompress_r = None
        if download.success:
            decompress_r = rctx.execute(cmd + [output_full])
            if decompress_r.return_code == 0:
                integrity = download.integrity
                break

        failed_attempts.append((index_url, download, decompress_r))

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

    return (output, integrity)

def _parse_url(url):
    scheme = ""
    host = ""
    path = "/"

    if "://" not in url:
        fail("Invalid URL: %s" % url)

    scheme, url_ = url.split("://", 1)

    if "/" in url_:
        host, path_ = url_.split("/", 1)
        path += path_
    else:
        host = url

    return struct(scheme = scheme, host = host, path = path)

def _make_file_url(pkg, root_url_, directory = None):
    root_url = _parse_url(root_url_)

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
        # relative to the sources.list directory/ so we combine them and
        # normalize the new 'Filename' path.
        #
        # Note that, so far, only the NVIDIA CUDA repos needed this workaround
        # so maybe this heuristic will break for other repos that don't conform
        # to the Debian repo spec.
        filename = paths.normalize(paths.join(directory, filename))

    file_url = "{}://{}{}".format(
        root_url.scheme,
        root_url.host,
        paths.join(root_url.path, filename),
    )

    return file_url, invalid_filename

def _parse_package_index(state, contents, arch, root_url, directory = None):
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
                fail("do not expect this. fix it.")

            last_key = key
            pkg[key] = value

        if len(pkg.keys()) != 0:
            pkg["FileUrl"], invalid_filename = _make_file_url(pkg, root_url, directory)

            if invalid_filename:
                out_of_spec.append(pkg["Package"])

            # NOTE: this fixes the arch for multi-arch flat repos
            arch_ = arch if pkg["Architecture"] == "all" else pkg["Architecture"]

            util.set_dict(state.packages, value = pkg, keys = (arch_, pkg["Package"], pkg["Version"]))
            last_key = ""
            pkg = {}
            total_pkgs += 1

    return out_of_spec, total_pkgs

def _package_versions(state, name, arch):
    if name not in state.packages[arch]:
        return []
    return state.packages[arch][name].keys()

def _package(state, name, version, arch):
    if name not in state.packages[arch]:
        return None
    if version not in state.packages[arch][name]:
        return None
    return state.packages[arch][name][version]

def _create(rctx, sources, archs):
    state = struct(
        packages = dict(),
    )

    for arch in archs:
        for source in sources:
            if len(source) == 2:  # flat repo
                url, directory = source
                index = directory
                dist, comp = None, None
            else:
                url, dist, comp = source
                index = "%s/%s" % (dist, comp)
                directory = None

            # We assume that `url` does not contain a trailing forward slash when passing to
            # functions below. If one is present, remove it. Some HTTP servers do not handle
            # redirects properly when a path contains "//"
            # (ie. https://mymirror.com/ubuntu//dists/noble/stable/... may return a 404
            # on misconfigured HTTP servers)
            url = url.rstrip("/")

            rctx.report_progress("Fetching %s package index: %s" % (arch, index))
            output, _ = _fetch_package_index(
                rctx,
                url,
                arch,
                dist = dist,
                comp = comp,
                directory = directory,
            )

            rctx.report_progress("Parsing %s package index: %s" % (arch, index))

            # TODO: this is expensive to perform.
            out_of_spec, total_pkgs = _parse_package_index(
                state,
                rctx.read(output),
                arch,
                url,
                directory,
            )

            if out_of_spec:
                count = len(out_of_spec)
                pct = int(100.0 * count / total_pkgs)
                msg = "Warning: {} index {} has {} packages ({}%) with invalid 'Filename' fields"
                print(msg.format(arch, index, count, pct))

    return struct(
        package_versions = lambda **kwargs: _package_versions(state, **kwargs),
        package = lambda **kwargs: _package(state, **kwargs),
    )

package_index = struct(
    new = _create,
)
