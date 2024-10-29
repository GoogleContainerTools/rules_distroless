"unit tests for package index"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apt/private:package_index.bzl", "package_index")
load(":mocks.bzl", "mock")

_TEST_SUITE_PREFIX = "package_index/"

def _fetch_package_index_test(ctx):
    env = unittest.begin(ctx)

    arch = "arm64"
    name = "foo"
    version = "0.3.20-1~bullseye.1"

    output = mock.packages_index(arch, name, version)

    url = "http://mirror.com"
    dist = "bullseye"
    comp = "main"

    mock_rctx = mock.rctx(
        read = mock.read(output),
        download = mock.download(success = True),
        execute = mock.execute([struct(return_code = 0)]),
    )

    actual = package_index._fetch_package_index(mock_rctx, url, dist, comp, arch)

    asserts.equals(env, output, actual)

    return unittest.end(env)

fetch_package_index_test = unittest.make(_fetch_package_index_test)

def _parse_package_index_test(ctx):
    env = unittest.begin(ctx)

    arch = "arm64"
    name = "foo"
    version = "0.3.20-1~bullseye.1"

    output = mock.packages_index(arch, name, version)

    url = "http://snapshot.foo.com/bar/baz"

    actual = {}
    package_index._parse_package_index(actual, output, arch, url)

    asserts.equals(env, "foo", actual[arch][name][version]["Package"])
    asserts.equals(env, url, actual[arch][name][version]["Root"])

    return unittest.end(env)

parse_package_index_test = unittest.make(_parse_package_index_test)

def _package_set_get_test(ctx):
    env = unittest.begin(ctx)

    arch = "arm64"
    name = "foo"
    version_1 = "1.5.1"
    version_2 = "1.5.2"

    pkg1 = mock.pkg(arch, name, version_1)
    pkg2 = mock.pkg(arch, name, version_2)

    parameters = [
        (
            [
                ((arch, name, version_1), pkg1),
                ((arch, name, version_2), pkg2),
            ],
            {arch: {name: {version_1: pkg1, version_2: pkg2}}},
        ),
    ]

    for keys_pkg, expected in parameters:
        actual = {}
        for keys, pkg_expected in keys_pkg:
            package_index._package_set(actual, keys = keys, package = pkg_expected)

            version = keys[-1]
            pkg_actual = package_index._package_get(actual, arch, name, version)

            asserts.equals(env, pkg_expected, pkg_actual)

        asserts.equals(env, expected, actual)

    versions_actual = package_index._package_get(actual, arch, name)
    asserts.equals(env, [version_1, version_2], versions_actual)

    return unittest.end(env)

package_set_get_test = unittest.make(_package_set_get_test)

def _index_test(ctx):
    env = unittest.begin(ctx)

    arch = "arm64"

    name = "foo"
    version = "0.3.20-1~bullseye.1"
    output = mock.packages_index(arch, name, version)

    url = "http://mirror.com"
    sources = [(url, "bullseye", "main")]

    mock_rctx = mock.rctx(
        read = mock.read(output),
        download = mock.download(success = True),
        execute = mock.execute([struct(return_code = 0)]),
    )

    actual = package_index._index(mock_rctx, sources = sources, archs = [arch])

    expected_pkg = mock.pkg(arch, name, version)
    expected_pkg["Root"] = url

    actual_pkg = actual.package_get(arch, name, version)
    asserts.equals(env, expected_pkg, actual_pkg)

    expected_packages = {arch: {name: {version: expected_pkg}}}
    asserts.equals(env, expected_packages, actual.packages)

    return unittest.end(env)

index_test = unittest.make(_index_test)

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
        actual = package_index.parse_depends(deps)
        asserts.equals(env, expected, actual)

    return unittest.end(env)

parse_depends_test = unittest.make(_parse_depends_test)

def package_index_tests():
    fetch_package_index_test(name = _TEST_SUITE_PREFIX + "_fetch_package_index")
    parse_package_index_test(name = _TEST_SUITE_PREFIX + "_parse_package_index")
    package_set_get_test(name = _TEST_SUITE_PREFIX + "_package_set_get")
    index_test(name = _TEST_SUITE_PREFIX + "_index")
    parse_depends_test(name = _TEST_SUITE_PREFIX + "parse_depends")
