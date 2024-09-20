"utilities"

# Map of Debian architectures to platform CPUs
# https://www.debian.org/ports/
# https://wiki.debian.org/SupportedArchitectures
#
# NOTE: the only architectures that need re-mapping are
# those that don't match a CPU or CPU alias in:
# https://github.com/bazelbuild/platforms/blob/main/cpu/BUILD
DEBIAN_ARCH_TO_CPU = {
    "amd64": "x86_64",
    "armhf": "armv7e-mf",  # NOTE: not sure that this is the right mapping :-/
    "mips64el": "mips64",
    "ppc64el": "ppc64le",
}

def _get_dupes(list_):
    set_ = {}
    dupes = []

    for value in list_:
        if value in set_:
            dupes.append(value)
        set_[value] = True

    return dupes

def _parse_url(url):
    if "://" not in url:
        fail("Invalid URL: %s" % url)

    scheme, url_ = url.split("://", 1)

    path = "/"

    if "/" in url_:
        host, path_ = url_.split("/", 1)
        path += path_
    else:
        host = url_

    return struct(scheme = scheme, host = host, path = path)

def _sanitize(str):
    return str.replace("+", "-p-").replace(":", "-").replace("~", "_")

util = struct(
    arch_to_cpu = lambda arch: DEBIAN_ARCH_TO_CPU.get(arch, arch),
    get_dupes = _get_dupes,
    parse_url = _parse_url,
    sanitize = _sanitize,
)
