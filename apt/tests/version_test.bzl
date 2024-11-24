"unit tests for version parsing"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apt/private:version.bzl", "version")

_TEST_SUITE_PREFIX = "version/"

def _parse_test(ctx):
    parameters = {
        "1:1.4.1-1": ("1", "1.4.1", "1"),
        "7.1.ds-1": (None, "7.1.ds", "1"),
        "10.11.1.3-2": (None, "10.11.1.3", "2"),
        "4.0.1.3.dfsg.1-2": (None, "4.0.1.3.dfsg.1", "2"),
        "0.4.23debian1": (None, "0.4.23debian1", None),
        "1.2.10+cvs20060429-1": (None, "1.2.10+cvs20060429", "1"),
        "0.2.0-1+b1": (None, "0.2.0", "1+b1"),
        "4.3.90.1svn-r21976-1": (None, "4.3.90.1svn-r21976", "1"),
        "1.5+E-14": (None, "1.5+E", "14"),
        "20060611-0.0": (None, "20060611", "0.0"),
        "0.52.2-5.1": (None, "0.52.2", "5.1"),
        "7.0-035+1": (None, "7.0", "035+1"),
        "1.1.0+cvs20060620-1+2.6.15-8": (None, "1.1.0+cvs20060620-1+2.6.15", "8"),
        "1.1.0+cvs20060620-1+1.0": (None, "1.1.0+cvs20060620", "1+1.0"),
        "4.2.0a+stable-2sarge1": (None, "4.2.0a+stable", "2sarge1"),
        "1.8RC4b": (None, "1.8RC4b", None),
        "0.9~rc1-1": (None, "0.9~rc1", "1"),
        "2:1.0.4+svn26-1ubuntu1": ("2", "1.0.4+svn26", "1ubuntu1"),
        "2:1.0.4~rc2-1": ("2", "1.0.4~rc2", "1"),
    }

    env = unittest.begin(ctx)

    for v, expected in parameters.items():
        actual = version.parse(v)
        asserts.equals(env, actual, expected)

    return unittest.end(env)

parse_test = unittest.make(_parse_test)

def _compare_test(ctx):
    parameters = [
        ("0", "<<", "a"),
        ("1.0", "<<", "1.1"),
        ("1.2", "<<", "1.11"),
        ("1.0-0.1", "<<", "1.1"),
        ("1.0-0.1", "<<", "1.0-1"),
        ("1.0", "=", "1.0"),
        ("1.0-0.1", "=", "1.0-0.1"),
        ("1:1.0-0.1", "=", "1:1.0-0.1"),
        ("1:1.0", "=", "1:1.0"),
        ("1.0-0.1", "<<", "1.0-1"),
        ("1.0final-5sarge1", ">>", "1.0final-5"),
        ("1.0final-5", ">>", "1.0a7-2"),
        ("0.9.2-5", "<<", "0.9.2+cvs.1.0.dev.2004.07.28-1.5"),
        ("1:500", "<<", "1:5000"),
        ("100:500", ">>", "11:5000"),
        ("1.0.4-2", ">>", "1.0pre7-2"),
        ("1.5~rc1", "<<", "1.5"),
        ("1.5~rc1", "<<", "1.5+b1"),
        ("1.5~rc1", "<<", "1.5~rc2"),
        ("1.5~rc1", ">>", "1.5~dev0"),
    ]

    env = unittest.begin(ctx)
    for va, op, vb in parameters:
        asserts.true(env, version.compare(va, op, vb))

    return unittest.end(env)

compare_test = unittest.make(_compare_test)

def _sort_test(ctx):
    parameters = [
        (
            ["1.5~rc2", "1.0.4-2", "1.5~rc1"],
            ["1.0.4-2", "1.5~rc1", "1.5~rc2"],
            False,
        ),
        (
            ["1.0a7-2", "1.0final-5sarge1", "1.0final-5"],
            ["1.0final-5sarge1", "1.0final-5", "1.0a7-2"],
            True,
        ),
    ]

    env = unittest.begin(ctx)

    for to_sort, expected, reversed in parameters:
        actual = version.sort(to_sort, reverse = reversed)
        asserts.equals(env, expected, actual)

    return unittest.end(env)

sort_test = unittest.make(_sort_test)

def version_tests():
    parse_test(name = _TEST_SUITE_PREFIX + "parse")
    compare_test(name = _TEST_SUITE_PREFIX + "compare")
    sort_test(name = _TEST_SUITE_PREFIX + "sort")
