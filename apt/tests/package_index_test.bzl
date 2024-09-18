"unit tests for package index"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apt/private:package_index.bzl", "package_index")
load(":mocks.bzl", "mock")

_TEST_SUITE_PREFIX = "package_index/"

def _fetch_package_index_test(ctx):
    env = unittest.begin(ctx)

    arch = "arm64"
    name = "foo"
    version = "0.3.20-1~bullseye.1"

    output = mock.packages_index(arch, name, version)

    url = "http://mirror.com"
    dist = "bullseye"
    comp = "main"

    mock_rctx = mock.rctx(
        read = mock.read(output),
        download = mock.download(success = True),
        execute = mock.execute([struct(return_code = 0)]),
    )

    actual = package_index._fetch_package_index(mock_rctx, url, dist, comp, arch)

    asserts.equals(env, output, actual)

    return unittest.end(env)

fetch_package_index_test = unittest.make(_fetch_package_index_test)

def _parse_package_index_test(ctx):
    env = unittest.begin(ctx)

    arch = "arm64"
    name = "foo"
    version = "0.3.20-1~bullseye.1"

    output = mock.packages_index(arch, name, version)

    url = "http://snapshot.foo.com/bar/baz"

    actual = {}
    package_index._parse_package_index(actual, output, arch, url)

    asserts.equals(env, "foo", actual[arch][name][version]["Package"])
    asserts.equals(env, url, actual[arch][name][version]["Root"])

    return unittest.end(env)

parse_package_index_test = unittest.make(_parse_package_index_test)

def _package_set_get_test(ctx):
    env = unittest.begin(ctx)

    arch = "arm64"
    name = "foo"
    version_1 = "1.5.1"
    version_2 = "1.5.2"

    pkg1 = mock.pkg(arch, name, version_1)
    pkg2 = mock.pkg(arch, name, version_2)

    parameters = [
        (
            [
                ((arch, name, version_1), pkg1),
                ((arch, name, version_2), pkg2),
            ],
            {arch: {name: {version_1: pkg1, version_2: pkg2}}},
        ),
    ]

    for keys_pkg, expected in parameters:
        actual = {}
        for keys, pkg_expected in keys_pkg:
            package_index._package_set(actual, keys = keys, package = pkg_expected)

            version = keys[-1]
            pkg_actual = package_index._package_get(actual, arch, name, version)

            asserts.equals(env, pkg_expected, pkg_actual)

        asserts.equals(env, expected, actual)

    versions_actual = package_index._package_get(actual, arch, name)
    asserts.equals(env, [version_1, version_2], versions_actual)

    return unittest.end(env)

package_set_get_test = unittest.make(_package_set_get_test)

def _new_test(ctx):
    env = unittest.begin(ctx)

    arch = "arm64"

    name = "foo"
    version = "0.3.20-1~bullseye.1"
    output = mock.packages_index(arch, name, version)

    url = "http://mirror.com"
    sources = [(url, "bullseye", "main")]

    mock_rctx = mock.rctx(
        read = mock.read(output),
        download = mock.download(success = True),
        execute = mock.execute([struct(return_code = 0)]),
    )

    actual = package_index.new(mock_rctx, sources = sources, archs = [arch])

    expected_pkg = mock.pkg(arch, name, version)
    expected_pkg["Root"] = url

    actual_pkg = actual.package_get(arch, name, version)
    asserts.equals(env, expected_pkg, actual_pkg)

    expected_packages = {arch: {name: {version: expected_pkg}}}
    asserts.equals(env, expected_packages, actual.packages)

    return unittest.end(env)

new_test = unittest.make(_new_test)

def package_index_tests():
    fetch_package_index_test(name = _TEST_SUITE_PREFIX + "_fetch_package_index")
    parse_package_index_test(name = _TEST_SUITE_PREFIX + "_parse_package_index")
    package_set_get_test(name = _TEST_SUITE_PREFIX + "_package_set_get")
    new_test(name = _TEST_SUITE_PREFIX + "new")
