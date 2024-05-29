"package index"

load(":util.bzl", "util")

def _fetch_package_index(rctx, url, dist, comp, arch, integrity):
    # Split the URL by the '://' delimiter
    protocol, rest = url.split("://")

    # Split the rest of the URL by the '/' delimiter and take the first part
    domain = rest.split("/")[0]

    target_triple = "{domain}/{dist}/{comp}/{arch}".format(domain = domain, dist = dist, comp = comp, arch = arch)

    file_types = {"xz": ["xz", "--decompress"], "gz": ["gzip", "-d"]}
    r = {"success": False, "integrity": None}

    decompression_successful = False
    for file_type, tool in file_types.items():
        output = "{}/Packages.{}".format(target_triple, file_type)
        urls = [
            "{}/dists/{}/{}/binary-{}/Packages.{}".format(url, dist, comp, arch, file_type),
            "{}/Packages.{}".format(url, file_type),
        ]
        for package_index_url in urls:
            r = rctx.download(
                url = package_index_url,
                output = output,
                integrity = integrity,
                allow_fail = True,
            )
            if r.success:
                print("Decompressing {} with {}".format(output, tool))
                re = rctx.execute(tool + [output])
                if re.return_code == 0:
                    decompression_successful = True
                    return ("{}/Packages".format(target_triple), r.integrity)
                else:
                    print("Decompression failed for {} with return code {}".format(output, re.return_code))

    if not r.success:
        fail("unable to download package index")

    if not decompression_successful:
        fail("unable to decompress package index")

    return ("{}/Packages".format(target_triple), r.integrity)

def _parse_package_index(state, contents, arch, root):
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
                fail("do not expect this. fix it.")

            last_key = key
            pkg[key] = value

        if len(pkg.keys()) != 0:
            pkg["Root"] = root
            util.set_dict(state.packages, value = pkg, keys = (arch, pkg["Package"], pkg["Version"]))
            last_key = ""
            pkg = {}

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
        for (url, dist, comp) in sources:
            # We assume that `url` does not contain a trailing forward slash when passing to
            # functions below. If one is present, remove it. Some HTTP servers do not handle
            # redirects properly when a path contains "//"
            # (ie. https://mymirror.com/ubuntu//dists/noble/stable/... may return a 404
            # on misconfigured HTTP servers)
            url = url.rstrip("/")

            rctx.report_progress("Fetching package index: {}/{}".format(dist, arch))
            (output, _) = _fetch_package_index(rctx, url, dist, comp, arch, "")

            # TODO: this is expensive to perform.
            rctx.report_progress("Parsing package index: {}/{}".format(dist, arch))
            _parse_package_index(state, rctx.read(output), arch, url)

    return struct(
        package_versions = lambda **kwargs: _package_versions(state, **kwargs),
        package = lambda **kwargs: _package(state, **kwargs),
    )

package_index = struct(
    new = _create,
)
