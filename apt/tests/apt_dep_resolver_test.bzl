"unit tests for resolution of package dependencies"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apt/private:apt_deb_repository.bzl", "deb_repository")
load("//apt/private:apt_dep_resolver.bzl", "dependency_resolver")
load("//apt/tests:apt_deb_repository_test.bzl", idx_mock_setup = "new_setup")
load("//apt/tests:mocks.bzl", "mock")

_TEST_SUITE_PREFIX = "apt_dep_resolver/"

def _pkg(name, **kwargs):
    pkg_ = {
        "package": name,
        "architecture": "amd64",
        "version": "2.38.1-5",
    }

    pkg_ |= kwargs

    return mock.pkg(**pkg_)

def _setup(pkgs):
    setup = idx_mock_setup(pkgs)

    idx_mock = deb_repository.new(
        setup.mock_rctx,
        sources = [(setup.url, setup.dist, setup.comp)],
        archs = [setup.arch],
    )

    resolution = dependency_resolver.new(idx_mock)

    return struct(
        idx_mock = idx_mock,
        resolution = resolution,
        arch = setup.arch,
        version = setup.version,
    )

def _resolve_optionals_test(ctx):
    env = unittest.begin(ctx)

    # Should pick the first alternative
    pkgs = [
        _pkg("libc6-dev"),
        _pkg("eject", depends = "libc6-dev | libc-dev"),
    ]

    setup = _setup(pkgs)

    root_package, dependencies = setup.resolution.resolve(
        mock.rctx(),
        arch = setup.arch,
        name = "eject",
        version = ("=", setup.version),
    )
    asserts.equals(env, "eject", root_package["Package"])
    asserts.equals(env, "libc6-dev", dependencies[0]["Package"])
    asserts.equals(env, 1, len(dependencies))

    return unittest.end(env)

resolve_optionals_test = unittest.make(_resolve_optionals_test)

def _resolve_arch_specific_packages_test(ctx):
    env = unittest.begin(ctx)

    #  Should pick bar for amd64 and foo for i386
    pkgs = [
        _pkg("foo", architecture = "i386"),
        _pkg("bar", architecture = "amd64"),
        _pkg("glibc", architecture = "all", depends = "foo [i386], bar [amd64]"),
    ]

    setup = _setup(pkgs)

    # bar for amd64
    root_package, dependencies = setup.resolution.resolve(
        mock.rctx(),
        arch = "amd64",
        name = "glibc",
        version = ("=", setup.version),
    )
    asserts.equals(env, "glibc", root_package["Package"])
    asserts.equals(env, "all", root_package["Architecture"])
    asserts.equals(env, "bar", dependencies[0]["Package"])
    asserts.equals(env, 1, len(dependencies))

    # foo for i386
    root_package, dependencies = setup.resolution.resolve(
        mock.rctx(),
        arch = "i386",
        name = "glibc",
        version = ("=", setup.version),
    )
    asserts.equals(env, "glibc", root_package["Package"])
    asserts.equals(env, "all", root_package["Architecture"])
    asserts.equals(env, "foo", dependencies[0]["Package"])
    asserts.equals(env, 1, len(dependencies))

    return unittest.end(env)

resolve_arch_specific_packages_test = unittest.make(_resolve_arch_specific_packages_test)

def _resolve_aliases_1(ctx):
    env = unittest.begin(ctx)

    pkgs = [
        _pkg("foo", depends = "bar (>= 1.0)"),
        _pkg("bar", version = "0.9"),
        _pkg("bar-plus", provides = "bar (= 1.0)"),
    ]

    setup = _setup(pkgs)

    root_package, dependencies = setup.resolution.resolve(
        mock.rctx(),
        arch = "amd64",
        name = "foo",
        version = ("=", setup.version),
    )
    asserts.equals(env, "foo", root_package["Package"])
    asserts.equals(env, "amd64", root_package["Architecture"])
    asserts.equals(env, "bar-plus", dependencies[0]["Package"])
    asserts.equals(env, 1, len(dependencies))

    return unittest.end(env)

resolve_aliases_1_test = unittest.make(_resolve_aliases_1)

def _resolve_aliases_2(ctx):
    env = unittest.begin(ctx)

    pkgs = [
        _pkg("foo", depends = "bar (>= 1.0)"),
        _pkg("bar", version = "0.9"),
        _pkg("bar-plus", provides = "bar (= 1.0)"),
        _pkg("bar-clone", provides = "bar"),
    ]

    setup = _setup(pkgs)

    root_package, dependencies = setup.resolution.resolve(
        mock.rctx(),
        arch = "amd64",
        name = "foo",
        version = ("=", setup.version),
    )
    asserts.equals(env, "foo", root_package["Package"])
    asserts.equals(env, "amd64", root_package["Architecture"])
    asserts.equals(env, "bar-plus", dependencies[0]["Package"])
    asserts.equals(env, 1, len(dependencies))

    return unittest.end(env)

resolve_aliases_2_test = unittest.make(_resolve_aliases_2)

def apt_dep_resolver_tests():
    resolve_optionals_test(name = _TEST_SUITE_PREFIX + "resolve_optionals")
    resolve_arch_specific_packages_test(name = _TEST_SUITE_PREFIX + "resolve_arch_specific")
    resolve_aliases_1_test(name = _TEST_SUITE_PREFIX + "resolve_aliases_1")
    resolve_aliases_2_test(name = _TEST_SUITE_PREFIX + "resolve_aliases_2")
