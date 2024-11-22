"unit tests for debian repositories"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apt/private:apt_deb_repository.bzl", "deb_repository")
load("//apt/private:manifest.bzl", "manifest")
load("//apt/private:nested_dict.bzl", "nested_dict")
load("//apt/tests:mocks.bzl", "mock", "mock_value")
load("//apt/tests:util.bzl", "test_util")

_TEST_SUITE_PREFIX = "apt_deb_repository/"

def new_setup(pkgs = None):
    if pkgs:
        arch = pkgs[0]["Architecture"]
        name = pkgs[0]["Version"]
        versions = [pkg["Version"] for pkg in pkgs]
    else:
        arch = mock_value.ARCH
        name = "foo"
        versions = ["0.3.20-1~bullseye.1", "1.5.1", "1.5.2"]

        pkgs = [
            mock.pkg(package = name, architecture = arch, version = v)
            for v in versions
        ]

    pkg_names = {p["Package"]: None for p in pkgs}.keys()

    mock_manifest = manifest.__test__._from_dict(
        mock.manifest_dict(packages = pkg_names, archs = [arch]),
        mock_value.MANIFEST_LABEL,
    )

    source = mock_manifest.sources[0]

    for idx in range(len(pkgs)):
        pkg = pkgs[idx]
        file_url, _ = deb_repository.__test__._make_file_url(pkg, source)
        pkg["File-Url"] = file_url

    packages_index_content = mock.packages_index_content(*pkgs)

    mock_rctx = mock.rctx(
        read = mock.read(packages_index_content),
        download = mock.download(success = True),
        execute = mock.execute([struct(return_code = 0)]),
    )

    return struct(
        pkgs = pkgs,
        pkg = pkgs[0],
        arch = arch,
        name = name,
        versions = versions,
        version = versions[0],
        packages_index_content = packages_index_content,
        manifest = mock_manifest,
        source = source,
        mock_rctx = mock_rctx,
    )

def _fetch_package_index_test(ctx):
    env = unittest.begin(ctx)

    setup = new_setup()

    actual = deb_repository.__test__._fetch_package_index(
        setup.mock_rctx,
        setup.source,
    )

    asserts.equals(env, setup.packages_index_content, actual)

    return unittest.end(env)

fetch_package_index_test = unittest.make(_fetch_package_index_test)

def _parse_package_index_test(ctx):
    env = unittest.begin(ctx)

    setup = new_setup()

    state = struct(
        packages = nested_dict.new(),
        virtual_packages = nested_dict.new(),
    )

    deb_repository.__test__._parse_package_index(
        state,
        setup.packages_index_content,
        setup.source,
    )

    actual_pkg = state.packages.get((setup.arch, setup.name, setup.version))

    test_util.asserts.dict_equals(env, setup.pkg, actual_pkg)

    return unittest.end(env)

parse_package_index_test = unittest.make(_parse_package_index_test)

def _new_test(ctx):
    env = unittest.begin(ctx)

    setup = new_setup()

    repository = deb_repository.new(setup.mock_rctx, setup.manifest)

    actual_versions = repository.package_versions(setup.arch, setup.name)
    asserts.equals(env, setup.versions, actual_versions)

    for expected_pkg in setup.pkgs:
        version = expected_pkg["Version"]

        actual_pkg = repository.package(setup.arch, setup.name, version)

        test_util.asserts.dict_equals(env, expected_pkg, actual_pkg)

    return unittest.end(env)

new_test = unittest.make(_new_test)

def apt_deb_repository_tests():
    fetch_package_index_test(name = _TEST_SUITE_PREFIX + "_fetch_package_index")
    parse_package_index_test(name = _TEST_SUITE_PREFIX + "_parse_package_index")
    new_test(name = _TEST_SUITE_PREFIX + "new")
