"pkg"

def _pkg_from_index(package, arch):
    return struct(
        name = package["Package"],
        version = package["Version"],
        url = "%s/%s" % (package["Root"], package["Filename"]),
        sha256 = package["SHA256"],
        arch = arch,
        dependencies = [],
    )

def _dep_from_pkg(p):
    return struct(
        name = p.name,
        # arch = p.arch,  # TODO: arch?
        version = p.version,
    )

def _pkg_from_lock_v2(package):
    package = dict(package)

    package["dependencies"] = [struct(**d) for d in package["dependencies"]]
    return struct(**package)

def _pkg_from_lock_v1(package):
    package = dict(package)

    package["dependencies"] = [
        struct(**{"name": d["name"], "version": d["version"]})
        for d in package["dependencies"]
    ]
    sorted(package["dependencies"], key = lambda d: (d.name, d.version))

    package.pop("key")

    return struct(**package)

pkg = struct(
    from_index = _pkg_from_index,
    from_lock_v2 = _pkg_from_lock_v2,
    from_lock_v1 = _pkg_from_lock_v1,
    add_dependency = lambda p, d: p.dependencies.append(_dep_from_pkg(d)),
)