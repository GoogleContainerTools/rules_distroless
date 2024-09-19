"pkg"

def _pkg_from_index(package, arch):
    return struct(
        name = package["Package"],
        version = package["Version"],
        url = package["FileUrl"],
        sha256 = package["SHA256"],
        arch = arch,
        dependencies = [],
    )

def _dep_from_index(package, arch):
    return struct(
        name = package["Package"],
        version = package["Version"],
    )

def _pkg_from_lock(package):
    package["dependencies"] = [struct(**d) for d in package["dependencies"]]
    return struct(**package)

def _pkg_from_lock_v1(package):
    package["dependencies"] = [
        struct(**{"name": d["name"], "version": d["version"]})
        for d in package["dependencies"]
    ]
    sorted(package["dependencies"], key = lambda d: (d.name, d.version))

    package.pop("key")

    return struct(**package)

pkg = struct(
    from_index = _pkg_from_index,
    from_lock = _pkg_from_lock,
    from_lock_v1 = _pkg_from_lock_v1,
)

dep = struct(
    from_index = _dep_from_index,
)
