"unit tests for pkg"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apt/private:pkg.bzl", "pkg")
load("//apt/tests:mocks.bzl", "mock_value")

_TEST_SUITE_PREFIX = "pkg/"

def _from_lock_versions_test(ctx):
    env = unittest.begin(ctx)

    pkg_versions = [
        (pkg.from_lock_v1, mock_value.PKG_LOCK_V1, mock_value.PKG_DEPS_V1),
        (pkg.from_lock_v2, mock_value.PKG_LOCK_V2, mock_value.PKG_DEPS_V2),
    ]

    for from_lock_v, pkg_lock, pkg_deps in pkg_versions:
        p = from_lock_v(pkg_lock)

        asserts.equals(env, pkg_lock["name"], p.name)
        asserts.equals(env, pkg_deps[0]["version"], p.dependencies[0].version)

    return unittest.end(env)

from_lock_versions_test = unittest.make(_from_lock_versions_test)

def _from_index_test(ctx):
    env = unittest.begin(ctx)

    arch = mock_value.ARCH
    p = pkg.from_index(mock_value.PKG_INDEX, arch)

    asserts.equals(env, arch, p.arch)
    asserts.equals(env, mock_value.PKG_INDEX["Package"], p.name)
    asserts.true(env, p.url, mock_value.PKG_INDEX["File-Url"])

    return unittest.end(env)

from_index_test = unittest.make(_from_index_test)

def pkg_tests():
    from_lock_versions_test(name = _TEST_SUITE_PREFIX + "from_lock_versions")
    from_index_test(name = _TEST_SUITE_PREFIX + "from_index")
