"lock"

load(":pkg.bzl", "dep", "pkg")

def __empty():
    return struct(version = 2, packages = {})

def __has_package(lock, p):
    return (
        p.name in lock.packages and
        p.arch in lock.packages[p.name] and
        p.version == lock.packages[p.name][p.arch].version
    )

def __add_package(lock, p, arch):
    if __has_package(lock, p):
        return

    if p.name not in lock.packages:
        lock.packages[p.name] = {}

    lock.packages[p.name][p.arch] = p

def _add_package(lock, package, arch, dependencies_to_add = None):
    dependencies_to_add = dependencies_to_add or []

    p = pkg.from_index(package, arch)

    __add_package(lock, p, arch)

    # NOTE: sorting the dependencies makes the contents
    # of the lock file stable and thus they diff better
    dependencies_to_add = sorted(
        dependencies_to_add,
        key = lambda p: (p["Package"], p["Version"]),
    )

    for dependency in dependencies_to_add:
        p_dep = pkg.from_index(dependency, arch)

        __add_package(lock, p_dep, arch)

        d = dep.from_index(dependency, arch)
        lock.packages[p.name][p.arch].dependencies.append(d)

def _as_json(lock):
    return json.encode_indent(
        struct(
            version = lock.version,
            packages = lock.packages,
        ),
    )

def _write(rctx, lock, out):
    return rctx.file(out, _as_json(lock))

def _create(rctx, lock):
    return struct(
        packages = lock.packages,
        add_package = lambda package, arch, dependencies_to_add: _add_package(
            lock,
            package,
            arch,
            dependencies_to_add,
        ),
        as_json = lambda: _as_json(lock),
        write = lambda out: _write(rctx, lock, out),
    )

def _empty(rctx):
    return _create(rctx, __empty())

def _from_lock_v1(lock_content):
    if lock_content["version"] != 1:
        fail("Invalid lockfile version: %s" % lock_content["version"])

    lockv2 = __empty()

    for package in lock_content["packages"]:
        p = pkg.from_lock_v1(package)
        __add_package(lockv2, p, p.arch)

    return lockv2

def _from_lock_v2(lock_content):
    if lock_content["version"] != 2:
        fail("Invalid lockfile version: %s" % lock_content["version"])

    lockv2 = __empty()

    for archs in lock_content["packages"].values():
        for package in archs.values():
            p = pkg.from_lock(package)
            __add_package(lockv2, p, p.arch)

    return lockv2

def _from_json(rctx, lock_content):
    lock_content = json.decode(lock_content)

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

    return _create(rctx, lock)

lockfile = struct(
    empty = _empty,
    from_json = _from_json,
)
