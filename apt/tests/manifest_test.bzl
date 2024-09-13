"unit tests for package index"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apt/private:manifest.bzl", "manifest")
load(":mocks.bzl", "mock")

_TEST_SUITE_PREFIX = "manifest/"

def _source_test(ctx):
    env = unittest.begin(ctx)

    arch = "arm64"

    src = {
        "arch": arch,
        "url": "http://mirror.com",
        "dist": "bullseye",
        "comp": "main",
    }

    actual = manifest._source(src)

    asserts.true(env, actual.index_full("foo").endswith(".foo"))

    return unittest.end(env)

source_test = unittest.make(_source_test)

def _from_dict_test(ctx):
    env = unittest.begin(ctx)

    url = "http://mirror.com"
    arch = "arm64"
    name = "foo"

    actual = mock.manifest(url, arch, name)

    asserts.equals(env, actual.label, "mock_manifest")

    return unittest.end(env)

from_dict_test = unittest.make(_from_dict_test)

def _lock_test(ctx):
    env = unittest.begin(ctx)

    arch = "arm64"
    name = "foo"
    version = "0.3.20-1~bullseye.1"

    output = mock.packages_index(arch, name, version)

    url = "http://mirror.com"

    manifest_ = mock.manifest(url, arch, name)

    mock_rctx = mock.rctx(
        read = mock.read(output),
        download = mock.download(success = True),
        execute = mock.execute([struct(return_code = 0)]),
    )

    actual = manifest._lock(
        mock_rctx,
        manifest_,
        include_transitive = True,
    )

    #asserts.equals(env, actual.label, manifest_label)

    return unittest.end(env)

lock_test = unittest.make(_lock_test)

def manifest_tests():
    source_test(name = _TEST_SUITE_PREFIX + "_source")
    from_dict_test(name = _TEST_SUITE_PREFIX + "_from_dict")
    lock_test(name = _TEST_SUITE_PREFIX + "_lock_test")
