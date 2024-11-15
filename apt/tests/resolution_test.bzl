"unit tests for resolution of package dependencies"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apt/private:package_index.bzl", package_index = "DO_NOT_DEPEND_ON_THIS_TEST_ONLY")
load("//apt/private:package_resolution.bzl", "package_resolution")
load("//apt/private:version_constraint.bzl", "version_constraint")

def _parse_depends_test(ctx):
    env = unittest.begin(ctx)

    parameters = {
        " | ".join([
            "libc6 (>= 2.2.1), default-mta",
            "mail-transport-agent",
        ]): [
            {"name": "libc6", "version": (">=", "2.2.1"), "arch": None},
            [
                {"name": "default-mta", "version": None, "arch": None},
                {"name": "mail-transport-agent", "version": None, "arch": None},
            ],
        ],
        ", ".join([
            "libluajit5.1-dev [i386 amd64 powerpc mips]",
            "liblua5.1-dev [hurd-i386 ia64 s390x sparc]",
        ]): [
            {
                "name": "libluajit5.1-dev",
                "version": None,
                "arch": ["i386", "amd64", "powerpc", "mips"],
            },
            {
                "name": "liblua5.1-dev",
                "version": None,
                "arch": ["hurd-i386", "ia64", "s390x", "sparc"],
            },
        ],
        " | ".join([
            "emacs",
            "emacsen, make, debianutils (>= 1.7)",
        ]): [
            [
                {"name": "emacs", "version": None, "arch": None},
                {"name": "emacsen", "version": None, "arch": None},
            ],
            {"name": "make", "version": None, "arch": None},
            {"name": "debianutils", "version": (">=", "1.7"), "arch": None},
        ],
        ", ".join([
            "libcap-dev [!kfreebsd-i386 !hurd-i386]",
            "autoconf",
            "debhelper (>> 5.0.0)",
            "file",
            "libc6 (>= 2.7-1)",
            "libpaper1",
            "psutils",
        ]): [
            {"name": "libcap-dev", "version": None, "arch": ["!kfreebsd-i386", "!hurd-i386"]},
            {"name": "autoconf", "version": None, "arch": None},
            {"name": "debhelper", "version": (">>", "5.0.0"), "arch": None},
            {"name": "file", "version": None, "arch": None},
            {"name": "libc6", "version": (">=", "2.7-1"), "arch": None},
            {"name": "libpaper1", "version": None, "arch": None},
            {"name": "psutils", "version": None, "arch": None},
        ],
        "python3:any": [
            {"name": "python3", "version": None, "arch": ["any"]},
        ],
        " | ".join([
            "gcc-i686-linux-gnu (>= 4:10.2)",
            "gcc:i386, g++-i686-linux-gnu (>= 4:10.2)",
            "g++:i386, dpkg-cross",
        ]): [
            [
                {"name": "gcc-i686-linux-gnu", "version": (">=", "4:10.2"), "arch": None},
                {"name": "gcc", "version": None, "arch": ["i386"]},
            ],
            [
                {"name": "g++-i686-linux-gnu", "version": (">=", "4:10.2"), "arch": None},
                {"name": "g++", "version": None, "arch": ["i386"]},
            ],
            {"name": "dpkg-cross", "version": None, "arch": None},
        ],
        " | ".join([
            "gcc-x86-64-linux-gnu (>= 4:10.2)",
            "gcc:amd64, g++-x86-64-linux-gnu (>= 4:10.2)",
            "g++:amd64, dpkg-cross",
        ]): [
            [
                {"name": "gcc-x86-64-linux-gnu", "version": (">=", "4:10.2"), "arch": None},
                {"name": "gcc", "version": None, "arch": ["amd64"]},
            ],
            [
                {"name": "g++-x86-64-linux-gnu", "version": (">=", "4:10.2"), "arch": None},
                {"name": "g++", "version": None, "arch": ["amd64"]},
            ],
            {"name": "dpkg-cross", "version": None, "arch": None},
        ],
    }

    for deps, expected in parameters.items():
        actual = version_constraint.parse_depends(deps)
        asserts.equals(env, expected, actual)

    return unittest.end(env)

parse_depends_test = unittest.make(_parse_depends_test)

_test_version = "2.38.1-5"
_test_arch = "amd64"

def _make_index():
    idx = package_index.new()
    resolution = package_resolution.new(idx)

    def _add_package(idx, **kwargs):
        kwargs["architecture"] = kwargs.get("architecture", _test_arch)
        kwargs["version"] = kwargs.get("version", _test_version)
        r = "\n".join(["{}: {}".format(item[0].title(), item[1]) for item in kwargs.items()])
        idx.parse_package_index(r)

    return struct(
        add_package = lambda **kwargs: _add_package(idx, **kwargs),
        resolution = resolution,
        reset = lambda: idx.reset(),
    )

def _resolve_optionals_test(ctx):
    env = unittest.begin(ctx)

    idx = _make_index()

    # Should pick the first alternative
    idx.add_package(package = "libc6-dev")
    idx.add_package(package = "eject", depends = "libc6-dev | libc-dev")

    (root_package, dependencies, _) = idx.resolution.resolve_all(
        name = "eject",
        version = ("=", _test_version),
        arch = _test_arch,
    )
    asserts.equals(env, "eject", root_package["Package"])
    asserts.equals(env, "libc6-dev", dependencies[0]["Package"])
    asserts.equals(env, 1, len(dependencies))

    return unittest.end(env)

resolve_optionals_test = unittest.make(_resolve_optionals_test)

def _resolve_architecture_specific_packages_test(ctx):
    env = unittest.begin(ctx)

    idx = _make_index()

    #  Should pick bar for amd64 and foo for i386
    idx.add_package(package = "foo", architecture = "i386")
    idx.add_package(package = "bar", architecture = "amd64")
    idx.add_package(package = "glibc", architecture = "all", depends = "foo [i386], bar [amd64]")

    # bar for amd64
    (root_package, dependencies, _) = idx.resolution.resolve_all(
        name = "glibc",
        version = ("=", _test_version),
        arch = "amd64",
    )
    asserts.equals(env, "glibc", root_package["Package"])
    asserts.equals(env, "all", root_package["Architecture"])
    asserts.equals(env, "bar", dependencies[0]["Package"])
    asserts.equals(env, 1, len(dependencies))

    # foo for i386
    (root_package, dependencies, _) = idx.resolution.resolve_all(
        name = "glibc",
        version = ("=", _test_version),
        arch = "i386",
    )
    asserts.equals(env, "glibc", root_package["Package"])
    asserts.equals(env, "all", root_package["Architecture"])
    asserts.equals(env, "foo", dependencies[0]["Package"])
    asserts.equals(env, 1, len(dependencies))

    return unittest.end(env)

resolve_architecture_specific_packages_test = unittest.make(_resolve_architecture_specific_packages_test)

def _resolve_aliases(ctx):
    env = unittest.begin(ctx)

    idx = _make_index()

    idx.add_package(package = "foo", depends = "bar (>= 1.0)")
    idx.add_package(package = "bar", version = "0.9")
    idx.add_package(package = "bar-plus", provides = "bar (= 1.0)")

    (root_package, dependencies, _) = idx.resolution.resolve_all(
        name = "foo",
        version = ("=", _test_version),
        arch = "amd64",
    )
    asserts.equals(env, "foo", root_package["Package"])
    asserts.equals(env, "amd64", root_package["Architecture"])
    asserts.equals(env, "bar-plus", dependencies[0]["Package"])
    asserts.equals(env, 1, len(dependencies))
    idx.reset()

    idx.add_package(package = "foo", depends = "bar (>= 1.0)")
    idx.add_package(package = "bar", version = "0.9")
    idx.add_package(package = "bar-plus", provides = "bar (= 1.0)")
    idx.add_package(package = "bar-clone", provides = "bar")

    (root_package, dependencies, _) = idx.resolution.resolve_all(
        name = "foo",
        version = ("=", _test_version),
        arch = "amd64",
    )
    asserts.equals(env, "foo", root_package["Package"])
    asserts.equals(env, "amd64", root_package["Architecture"])
    asserts.equals(env, "bar-plus", dependencies[0]["Package"])
    asserts.equals(env, 1, len(dependencies))

    return unittest.end(env)

resolve_aliases_test = unittest.make(_resolve_aliases)

_TEST_SUITE_PREFIX = "package_resolution/"

def resolution_tests():
    parse_depends_test(name = _TEST_SUITE_PREFIX + "parse_depends")
    resolve_optionals_test(name = _TEST_SUITE_PREFIX + "resolve_optionals")
    resolve_architecture_specific_packages_test(name = _TEST_SUITE_PREFIX + "resolve_architectures_specific")
    resolve_aliases_test(name = _TEST_SUITE_PREFIX + "resolve_aliases")
