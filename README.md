# `rules_distroless`

Bazel helper rules to aid with some of the steps needed to create a Linux /
Debian installation. These rules are designed to replace commands such as
`apt-get install`, `passwd`, `groupadd`, `useradd`, `update-ca-certificates`.

> [!CAUTION] > `rules_distroless` is currently in beta and does not yet offer a stable
> Public API. However, many users are already successfully using it in
> production environments. Check [Adopters](#adopters) to see who's already
> using it.

# Usage

## Bzlmod (Bazel 6+)

> [!NOTE]
> If you are using Bazel 6 you need to enable Bzlmod by adding `common --enable_bzlmod` to `.bazelrc`
> If you are using Bazel 7+ [it's enabled by default].

Add the following to your `MODULE.bazel` file:

```starlark
bazel_dep(name = "rules_distroless", version = "0.3.9")
```

You can find the latest release version in the [Bazel Central Registry].

If you want to use a specific commit (e.g. there are commits in `main` that are
still not part of a release) you can use one of the few mechanisms that Bazel
provides to override repos.

You can use [`git_override`], [`archive_override`], etc (or
[`local_path_override`] if you want to test a local patch):

```starlark
bazel_dep(name = "rules_distroless", version = "0.3.9")

git_override(
    module_name = "rules_distroless",
    remote = "https://github.com/GoogleContainerTools/rules_distroless.git",
    commit = "6ccc0307f618e67a9252bc6ce2112313c2c42b7f",
)
```

## `WORKSPACE` (legacy)

> [!WARNING]
> Bzlmod is replacing the legacy `WORKSPACE` system. The `WORKSPACE` file will
> be disabled by default in Bazel 8 (late 2024) and will be completely removed
> in Bazel 9 (late 2025). Please migrate to Bzlmod following the steps in the
> [Bzlmod migration guide].

Add the following to your `WORKSPACE` file:

```starlark
REPO = "https://github.com/GoogleContainerTools/rules_distroless"

VERSION = "0.3.8"
SHA256 = "6d1d739617e48fc3579781e694d3fabb08fc6c9300510982c01882732c775b8e"
URL = "{repo}/releases/download/v{v}/rules_distroless-v{v}.tar.gz".format(repo=REPO, v=VERSION)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "rules_distroless",
    sha256 = SHA256,
    strip_prefix = "rules_distroless-{}".format(VERSION),
    url = URL,
)
```

You can find the latest release in the [`rules_distroless` Github releases
page].

If you want to use a specific commit (e.g. there are commits in `main` that are
still not part of a release) you can change the Github URL pointing it to a
Github archive, as follows:

```starlark
REPO = "https://github.com/GoogleContainerTools/rules_distroless"

COMMIT = "6ccc0307f618e67a9252bc6ce2112313c2c42b7f"
SHA256 = ""
URL = "{}/archive/{}.tar.gz".format(REPO, COMMIT)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "rules_distroless",
    sha256 = SHA256,
    strip_prefix = "rules_distroless-{}".format(COMMIT),
    url = URL,
)
```

Note that the `SHA256` is initially empty. This is the easiest way to get the
correct value because Bazel will print a warning message with the hash so you
can use it to get rid of the warning.

> [!CAUTION]
> GitHub source archives don't have a strong guarantee on the sha256 stability.
> Check Github's [Update on the future stability of source code archives and
>
> > hashes] for more information.

# Examples

The [examples](/examples) demonstrate how to accomplish typical tasks such as
**create a new user group** or **create a new home directory**:

- [groupadd](/examples/group)
- [passwd](/examples/passwd)
- [useradd --home](/examples/home)
- [update-ca-certificates](/examples/cacerts)
- [keytool](/examples/java_keystore)
- [apt-get install](/examples/debian_snapshot) from Debian repositories.
- [apt-get install](/examples/ubuntu_snapshot) from Ubuntu repositories.

We also have `distroless`-specific rules that could be useful:

- [flatten](/examples/flatten): flatten multiple `tar` archives.
- [os_release](/examples/os_release): create an `/etc/os-release` file.
- [locale](/examples/locale): strip `/usr/lib/locale` to be smaller.
- [dpkg_statusd](/examples/statusd): creates a `/var/lib/dpkg/status.d`
  package database for scanners to discover installed packages.

# Public API Docs

To read more specific documentation for each of the rules in the repo please
check the following docs:

- [apt](/docs/apt.md): repository rule for installing Debian/Ubuntu packages.
- [apt macro](/docs/apt_macro.md): legacy macro for installing Debian/Ubuntu
  packages.
- [rules](/docs/rules.md): various helper rules to aid with creating a Linux /
  Debian installation from scratch.

# Contributing

This ruleset is primarily funded to support [Google's `distroless` container
images]. We may not work on feature requests that do not support this mission.

We will however accept fully tested contributions via pull requests if they
align with the project goals (e.g. add support for a different compression
format) and may reject requests that do not (e.g. supporting other packaging
formats other than `.deb`).

# Adopters

- [Google's `distroless` container images]
- [Arize AI](https://www.arize.com)

> [!TIP]
> Are you using `rules_distroless`? Please send us a Pull Request to add your
> project or company name here!

[it's enabled by default]: https://blog.bazel.build/2023/12/11/bazel-7-release.html#bzlmod
[bazel central registry]: https://registry.bazel.build/modules/rules_distroless
[`git_override`]: https://bazel.build/versions/6.0.0/rules/lib/globals#git_override
[`archive_override`]: https://bazel.build/versions/6.0.0/rules/lib/globals#archive_override
[`local_path_override`]: https://bazel.build/versions/6.0.0/rules/lib/globals#local_path_override
[bzlmod migration guide]: https://bazel.build/external/migration
[`rules_distroless` github releases page]: https://github.com/GoogleContainerTools/rules_distroless/releases
[update on the future stability of source code archives and hashes]: https://github.blog/2023-02-21-update-on-the-future-stability-of-source-code-archives-and-hashes
[google's `distroless` container images]: https://github.com/GoogleContainerTools/distroless
[arize ai]: https://www.arize.com
