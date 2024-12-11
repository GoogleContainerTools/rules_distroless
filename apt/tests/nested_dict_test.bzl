"unit tests for nested dict"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apt/private:nested_dict.bzl", "nested_dict")

_TEST_SUITE_PREFIX = "nested_dict/"

def _get_empty_test(ctx):
    env = unittest.begin(ctx)

    nd = nested_dict.new()

    asserts.equals(env, None, nd.get(keys = []))

    return unittest.end(env)

get_empty_test = unittest.make(_get_empty_test)

def _set_get_test(ctx, nd = None):
    env = unittest.begin(ctx)

    nd = nd or nested_dict.new()

    keys = ["foo", "bar", 42]
    value = 31415927

    nd.set(keys = keys, value = value)

    asserts.true(env, nd.has(keys))
    asserts.equals(env, value, nd.get(keys))

    other_keys = ["foo", "bar", 43]
    asserts.equals(env, False, nd.has(other_keys))

    return unittest.end(env)

set_get_test = unittest.make(_set_get_test)

def _add_get_test(ctx, nd = None):
    env = unittest.begin(ctx)

    nd = nd or nested_dict.new()

    keys = ["foobar", "baz"]

    values = [1, 2, 3]

    for value in values:
        nd.add(keys = keys, value = value)

    asserts.true(env, nd.has(keys))
    asserts.equals(env, values, nd.get(keys))

    return unittest.end(env)

add_get_test = unittest.make(_add_get_test)

def _clear_test(ctx):
    env = unittest.begin(ctx)

    nd = nested_dict.new()

    _set_get_test(ctx, nd)
    _add_get_test(ctx, nd)

    all_keys = [
        ["foobar", "baz"],
        ["foo", "bar", 42],
    ]

    for keys in all_keys:
        asserts.true(env, nd.has(keys))

    nd.clear()

    for keys in all_keys:
        asserts.equals(env, False, nd.has(keys))

    return unittest.end(env)

clear_test = unittest.make(_clear_test)

def nested_dict_tests():
    get_empty_test(name = _TEST_SUITE_PREFIX + "get_empty")
    set_get_test(name = _TEST_SUITE_PREFIX + "set_get")
    add_get_test(name = _TEST_SUITE_PREFIX + "add_get")
    clear_test(name = _TEST_SUITE_PREFIX + "clear")
