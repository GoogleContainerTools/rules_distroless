"unit tests for util"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apt/private:util.bzl", "util")

_TEST_SUITE_PREFIX = "util/"

def _parse_url_test(ctx):
    env = unittest.begin(ctx)

    parameters = {
        "https://mirror.com": struct(scheme = "https", host = "mirror.com", path = "/"),
        "http://mirror.com/foo/bar": struct(scheme = "http", host = "mirror.com", path = "/foo/bar"),
    }

    for url, expected in parameters.items():
        actual = util.parse_url(url)
        asserts.equals(env, expected, actual)

    return unittest.end(env)

parse_url_test = unittest.make(_parse_url_test)

def util_tests():
    parse_url_test(name = _TEST_SUITE_PREFIX + "parse_url")
