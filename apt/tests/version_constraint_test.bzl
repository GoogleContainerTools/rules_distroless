"unit tests for version constraint"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apt/private:version_constraint.bzl", "version_constraint")

_TEST_SUITE_PREFIX = "version_constraint/"

def _parse_version_constraint_test(ctx):
    parameters = {
        ">= 1.4.1": (">=", "1.4.1"),
        "<< 7.1.ds-1": ("<<", "7.1.ds-1"),
    }

    env = unittest.begin(ctx)

    for vac, expected in parameters.items():
        actual = version_constraint.parse_version_constraint(vac)
        asserts.equals(env, actual, expected)

    return unittest.end(env)

parse_version_constraint_test = unittest.make(_parse_version_constraint_test)

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

def _is_satisfied_by_test(ctx):
    parameters = [
        (">= 1.1", "= 1.1", True),
        ("<= 1.1", "= 1.1", True),
        (">> 1.1", "= 1.1", False),
    ]

    env = unittest.begin(ctx)
    for va, vb, expected in parameters:
        asserts.equals(
            env,
            expected,
            version_constraint.is_satisfied_by(
                version_constraint.parse_version_constraint(va),
                version_constraint.parse_version_constraint(vb)[1],
            ),
        )

    return unittest.end(env)

is_satisfied_by_test = unittest.make(_is_satisfied_by_test)

def version_constraint_tests():
    parse_version_constraint_test(
        name = _TEST_SUITE_PREFIX + "parse_version_constraint_test",
    )
    parse_depends_test(name = _TEST_SUITE_PREFIX + "parse_depends")
    is_satisfied_by_test(name = _TEST_SUITE_PREFIX + "is_satisfied_by")
