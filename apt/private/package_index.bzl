"package index"

load(":util.bzl", "util")

def _fetch_package_index(rctx, url, dist, comp, arch, integrity):
    target_triple = "{dist}/{comp}/{arch}".format(dist = dist, comp = comp, arch = arch)
    output = "{}/Packages.xz".format(target_triple)
    r = rctx.download(
        url = "{}/dists/{}/{}/binary-{}/Packages.xz".format(url, dist, comp, arch),
        output = output,
        integrity = integrity,
    )
    rctx.execute([
        "xz",
        "--decompress",
        output,
    ])
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
            split = line.split(":")
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
