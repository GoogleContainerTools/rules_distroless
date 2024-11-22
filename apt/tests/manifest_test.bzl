"unit tests for manifest"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apt/private:lockfile.bzl", "lockfile")
load("//apt/private:manifest.bzl", "manifest")
load(":mocks.bzl", "mock", "mock_value")

_TEST_SUITE_PREFIX = "manifest/"

def _source_test(ctx):
    env = unittest.begin(ctx)

    actual = manifest.__test__._source(dict(mock_value.SOURCE))

    asserts.true(env, actual.index_full("foo").endswith(".foo"))

    return unittest.end(env)

source_test = unittest.make(_source_test)

def _from_dict_test(ctx):
    env = unittest.begin(ctx)

    actual = manifest.__test__._from_dict(
        mock.manifest_dict(packages = ["foo"]),
        mock_value.MANIFEST_LABEL,
    )

    asserts.equals(env, actual.version, manifest.VERSION)
    asserts.equals(env, actual.label, mock_value.MANIFEST_LABEL)

    return unittest.end(env)

from_dict_test = unittest.make(_from_dict_test)

def _lock_test(ctx):
    env = unittest.begin(ctx)

    pkg = mock_value.PKG_INDEX
    output = mock.packages_index_content(pkg)

    mock_manifest = manifest.__test__._from_dict(
        mock.manifest_dict(packages = [pkg["Package"]]),
        mock_value.MANIFEST_LABEL,
    )

    mock_rctx = mock.rctx(
        read = mock.read(output),
        download = mock.download(success = True),
        execute = mock.execute([struct(return_code = 0)]),
    )

    actual_lock = manifest.__test__._lock(
        mock_rctx,
        mock_manifest,
        include_transitive = True,
    )

    asserts.equals(env, lockfile.VERSION, actual_lock.version)

    pkg_lock = actual_lock.get_package(pkg, mock_value.ARCH)

    asserts.equals(env, pkg["Package"], pkg_lock.name)
    asserts.equals(env, pkg["Architecture"], pkg_lock.arch)
    asserts.equals(env, pkg["Version"], pkg_lock.version)
    asserts.equals(env, [], pkg_lock.dependencies)

    return unittest.end(env)

lock_test = unittest.make(_lock_test)

def manifest_tests():
    source_test(name = _TEST_SUITE_PREFIX + "_source")
    from_dict_test(name = _TEST_SUITE_PREFIX + "_from_dict")
    lock_test(name = _TEST_SUITE_PREFIX + "_lock_test")
