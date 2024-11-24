"unit tests for lockfile"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apt/private:lockfile.bzl", "lockfile")
load("//apt/tests:mocks.bzl", "mock", "mock_value")
load("//apt/tests:util.bzl", "test_util")

_TEST_SUITE_PREFIX = "lockfile/"

def _from_lock_v1_test(ctx):
    env = unittest.begin(ctx)

    lock = lockfile.__test__._from_json(mock.rctx(), mock_value.LOCK_V1)

    asserts.equals(env, lockfile.VERSION, lock.version)

    expected = len(mock_value.LOCK_V1["packages"])
    actual = len(lock.packages())
    asserts.equals(env, expected, actual)

    expected = dict(mock_value.LOCK_V1["packages"][1])

    # deleting "key" from expected because V2 drops it
    expected.pop("key")
    expected["dependencies"] = [dict(d) for d in expected["dependencies"]]
    for d in expected["dependencies"]:
        d.pop("key")

    arch = mock_value.ARCH

    actuals = [
        lock.get_package(mock_value.PKG_INDEX, arch),
        lock.packages()[1],
    ]

    for actual in actuals:
        actual_dict = json.decode(actual.to_json())
        test_util.asserts.dict_equals(env, expected, actual_dict)

    return unittest.end(env)

from_lock_v1_test = unittest.make(_from_lock_v1_test)

def _from_lock_v2_test(ctx):
    env = unittest.begin(ctx)

    lock = lockfile.__test__._from_json(mock.rctx(), mock_value.LOCK_V2)

    asserts.equals(env, lockfile.VERSION, lock.version)

    expected = 2
    actual = len(lock.packages())
    asserts.equals(env, expected, actual)

    arch = mock_value.ARCH
    expected = mock_value.LOCK_V2["packages"]["dpkg"][arch]

    actuals = [
        lock.get_package(mock_value.PKG_INDEX, arch),
        lock.packages()[0],
    ]

    for actual in actuals:
        actual_dict = json.decode(actual.to_json())
        test_util.asserts.dict_equals(env, expected, actual_dict)

    return unittest.end(env)

from_lock_v2_test = unittest.make(_from_lock_v2_test)

def _add_package_test(ctx):
    env = unittest.begin(ctx)

    lock = lockfile.new(mock.rctx())

    asserts.equals(env, lockfile.VERSION, lock.version)

    arch = mock_value.ARCH

    # no deps
    lock.add_package(mock_value.PKG_INDEX, arch, [])

    expected = dict(mock_value.PKG_LOCK_V2)
    expected["dependencies"] = []

    actual = lock.get_package(mock_value.PKG_INDEX, arch)
    actual_dict = json.decode(actual.to_json())

    test_util.asserts.dict_equals(env, expected, actual_dict)

    # with deps

    lock.add_package(mock_value.PKG_INDEX, arch, mock_value.PKG_INDEX_DEPS)

    expected = mock_value.PKG_LOCK_V2

    actual = lock.get_package(mock_value.PKG_INDEX, arch)
    actual_dict = json.decode(actual.to_json())

    test_util.asserts.dict_equals(env, expected, actual_dict)

    return unittest.end(env)

add_package_test = unittest.make(_add_package_test)

def lockfile_tests():
    from_lock_v1_test(name = _TEST_SUITE_PREFIX + "from_lock_v1")
    from_lock_v2_test(name = _TEST_SUITE_PREFIX + "from_lock_v2")
    add_package_test(name = _TEST_SUITE_PREFIX + "add_package")
