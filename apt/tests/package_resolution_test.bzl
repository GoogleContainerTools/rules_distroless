"unit tests for version parsing"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apt/private:package_resolution.bzl", "package_resolution")

_TEST_SUITE_PREFIX = "package_resolution/"

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
        actual = package_resolution.parse_depends(deps)
        asserts.equals(env, expected, actual)

    return unittest.end(env)

parse_depends_test = unittest.make(_parse_depends_test)

def package_resolution_tests():
    parse_depends_test(name = _TEST_SUITE_PREFIX + "parse_depends")
