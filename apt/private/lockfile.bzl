"lock"

load(":nested_dict.bzl", "nested_dict")
load(":pkg.bzl", "pkg")

VERSION = 2

def _empty():
    return struct(version = VERSION, packages = nested_dict.new())

def _add_package(lock, package, arch, dependencies_to_add = None):
    dependencies_to_add = [
        pkg.from_index(d, arch)
        for d in dependencies_to_add or []
    ]

    # NOTE: sorting the dependencies makes the contents
    # of the lock file stable and thus they diff better
    dependencies_to_add = sorted(
        dependencies_to_add,
        key = lambda d: (d.name, d.version),
    )

    p = pkg.from_index(package, arch)

    for p_dep in dependencies_to_add:
        pkg.add_dependency(p, p_dep)
        lock.packages.set(keys = (p_dep.name, arch), value = p_dep)

    lock.packages.set(keys = (p.name, arch), value = p)

def _get_package(lock, package, arch):
    p = pkg.from_index(package, arch)
    return lock.packages.get(keys = (p.name, arch))

def _as_json(lock):
    return json.encode_indent(
        struct(
            version = lock.version,
            packages = lock.packages.as_dict(),
        ),
    )

def _write(rctx, lock, out):
    return rctx.file(out, _as_json(lock))

def _packages(lock):
    return [
        package
        for archs in lock.packages.values()
        for package in archs.values()
    ]

def _get_architectures(lock, package_name):
    return lock.packages.get(keys = (package_name,))

def _new(rctx, lock = None):
    lock = lock or _empty()

    return struct(
        version = lock.version,
        packages = lambda: _packages(lock),
        add_package = lambda package, arch, dependencies_to_add: _add_package(
            lock,
            package,
            arch,
            dependencies_to_add,
        ),
        get_package = lambda package, arch: _get_package(lock, package, arch),
        get_architectures = lambda package_name: _get_architectures(lock, package_name),
        as_json = lambda: _as_json(lock),
        write = lambda out: _write(rctx, lock, out),
    )

def _from_lock_v1(lock_content):
    if lock_content["version"] != 1:
        fail("Invalid lockfile version: %s" % lock_content["version"])

    lockv2 = _empty()

    for package in lock_content["packages"]:
        p = pkg.from_lock_v1(package)
        lockv2.packages.set(keys = (p.name, p.arch), value = p)

    return lockv2

def _from_lock_v2(lock_content):
    if lock_content["version"] != 2:
        fail("Invalid lockfile version: %s" % lock_content["version"])

    lockv2 = _empty()

    for archs in lock_content["packages"].values():
        for package in archs.values():
            p = pkg.from_lock_v2(package)
            lockv2.packages.set(keys = (p.name, p.arch), value = p)

    return lockv2

def _from_json(rctx, lock_content):
    if lock_content["version"] == 2:
        lock = _from_lock_v2(lock_content)
    elif lock_content["version"] == 1:
        print(
            "\n\nAuto-converting lockfile format from v1 to v2. " +
            "To permanently convert an existing lockfile please run " +
            "`bazel run @<REPO>//:lock`\n\n",
        )

        lock = _from_lock_v1(lock_content)
    else:
        fail("Invalid lockfile version: %s" % lock_content["version"])

    return _new(rctx, lock)

lockfile = struct(
    VERSION = VERSION,
    new = lambda rctx: _new(rctx),
    from_json = lambda rctx, lock_content: _from_json(rctx, json.decode(lock_content)),
    __test__ = struct(
        _from_json = _from_json,
    ),
)
