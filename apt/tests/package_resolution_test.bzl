"unit tests for version parsing"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apt/private:package_resolution.bzl", "package_resolution")

def _parse_depends_test(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        [
            {"name": "libc6", "version": (">=", "2.2.1"), "arch": None},
            [{"name": "default-mta", "version": None, "arch": None}, {"name": "mail-transport-agent", "version": None, "arch": None}],
        ],
        package_resolution.parse_depends("libc6 (>= 2.2.1), default-mta | mail-transport-agent"),
    )

    asserts.equals(
        env,
        [
            {"name": "libluajit5.1-dev", "version": None, "arch": ["i386", "amd64", "kfreebsd-i386", "armel", "armhf", "powerpc", "mips"]},
            {"name": "liblua5.1-dev", "version": None, "arch": ["hurd-i386", "ia64", "kfreebsd-amd64", "s390x", "sparc"]},
        ],
        package_resolution.parse_depends("libluajit5.1-dev [i386 amd64 kfreebsd-i386 armel armhf powerpc mips], liblua5.1-dev [hurd-i386 ia64 kfreebsd-amd64 s390x sparc]"),
    )

    asserts.equals(
        env,
        [
            [
                {"name": "emacs", "version": None, "arch": None},
                {"name": "emacsen", "version": None, "arch": None},
            ],
            {"name": "make", "version": None, "arch": None},
            {"name": "debianutils", "version": (">=", "1.7"), "arch": None},
        ],
        package_resolution.parse_depends("emacs | emacsen, make, debianutils (>= 1.7)"),
    )

    asserts.equals(
        env,
        [
            {"name": "libcap-dev", "version": None, "arch": ["!kfreebsd-i386", "!kfreebsd-amd64", "!hurd-i386"]},
            {"name": "autoconf", "version": None, "arch": None},
            {"name": "debhelper", "version": (">>", "5.0.0"), "arch": None},
            {"name": "file", "version": None, "arch": None},
            {"name": "libc6", "version": (">=", "2.7-1"), "arch": None},
            {"name": "libpaper1", "version": None, "arch": None},
            {"name": "psutils", "version": None, "arch": None},
        ],
        package_resolution.parse_depends("libcap-dev [!kfreebsd-i386 !kfreebsd-amd64 !hurd-i386], autoconf, debhelper (>> 5.0.0), file, libc6 (>= 2.7-1), libpaper1, psutils"),
    )

    asserts.equals(
        env,
        [
            {"name": "python3", "version": None, "arch": ["any"]},
        ],
        package_resolution.parse_depends("python3:any"),
    )

    asserts.equals(
        env,
        [
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
        package_resolution.parse_depends("gcc-i686-linux-gnu (>= 4:10.2) | gcc:i386, g++-i686-linux-gnu (>= 4:10.2) | g++:i386, dpkg-cross"),
    )

    asserts.equals(
        env,
        [
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
        package_resolution.parse_depends("gcc-x86-64-linux-gnu (>= 4:10.2) | gcc:amd64, g++-x86-64-linux-gnu (>= 4:10.2) | g++:amd64, dpkg-cross"),
    )

    return unittest.end(env)

version_depends_test = unittest.make(_parse_depends_test)
