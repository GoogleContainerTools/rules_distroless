"unit tests for util"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apt/private:util.bzl", "util")

_TEST_SUITE_PREFIX = "util/"

def _sanitize_test(ctx):
    env = unittest.begin(ctx)

    parameters = {
        "3.0.6+dfsg-4": "3.0.6-p-dfsg-4",
        "8.8.1+ds+~cs25.17.7-2": "8.8.1-p-ds-p-_cs25.17.7-2",
        "1:2020.1commit85143dcb-4": "1-2020.1commit85143dcb-4",
    }

    for s, expected in parameters.items():
        actual = util.sanitize(s)
        asserts.equals(env, expected, actual)

    return unittest.end(env)

sanitize_test = unittest.make(_sanitize_test)

def util_tests():
    sanitize_test(name = _TEST_SUITE_PREFIX + "sanitize")
