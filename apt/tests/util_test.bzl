"unit tests for util"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apt/private:util.bzl", "util")

_TEST_SUITE_PREFIX = "util/"

def _escape_test(ctx):
    env = unittest.begin(ctx)

    parameters = {
        "": "",
        "foo": "foo",
        '"foo"': '"foo"',
        "\\e": "\\\\e",
        "\n": "\\n",
    }

    for s, expected in parameters.items():
        actual = util.escape(s)

    return unittest.end(env)

escape_test = unittest.make(_escape_test)

def _get_dupes_test(ctx):
    env = unittest.begin(ctx)

    parameters = {
        (): [],
        (1, 2, 3): [],
        (2, 1, 2, 2, 3, 1): [1, 2],
    }

    for l, expected in parameters.items():
        actual = util.get_dupes(list(l))
        asserts.equals(env, expected, actual)

    return unittest.end(env)

get_dupes_test = unittest.make(_get_dupes_test)

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
    escape_test(name = _TEST_SUITE_PREFIX + "escape")
    get_dupes_test(name = _TEST_SUITE_PREFIX + "get_dupes")
    parse_url_test(name = _TEST_SUITE_PREFIX + "parse_url")
    sanitize_test(name = _TEST_SUITE_PREFIX + "sanitize")
