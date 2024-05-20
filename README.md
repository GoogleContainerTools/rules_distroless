# Bazel rules for fetching Debian packages

This ruleset designed to replace commands such as `apt-get install`, `passwd`, `groupadd`, `useradd`, `update-ca-certificates`.

> [!NOTE]
> rules_distroless is an beta software and doesn't have a stable Public API yet, however many are already using it in production.
>
> See [Adopters](#adopters) section to see who's already using it.

# Usage

Our [examples](/examples) demonstrate how to accomplish typical tasks such as <b>create a new user group</b> or <b>create a new home directory</b>.

- [groupadd](/examples/group)
- [passwd](/examples/passwd)
- [useradd --home](/examples/home)
- [update-ca-certificates](/examples/cacerts)
- [keytool](/examples/java_keystore)
- [apt-get install](/examples/debian_snapshot) <i>from Debian repositories.</i>
- [apt-get install](/examples/ubuntu_snapshot) <i>from Ubuntu repositories.</i>

We also we have distroless-specific rules that could be useful 

- [flatten](/examples/flatten): <i>flatten multiple `tar` archives.</s>
- [os_release](/examples/os_release): <i>create a `/etc/os-release` file</s>
- [locale](/examples/locale): <i>strip `/usr/lib/locale` to be smaller.</s>
- [dpkg_statusd](/examples/statusd): <i>creates a package database at /var/lib/dpkg/status.d for scanners to discover installed packages.</i>


# Public API Docs

- [apt](/docs/apt.md) Repository rule for fetching/installing Debian/Ubuntu packages.
- [linux](/docs/rules.md) Various rules for creating Linux specific files.


## Installation

See the install instructions on the release notes: <https://github.com/GoogleContainerTools/rules_distroless/releases>

To use a commit rather than a release, you can point at any SHA of the repo.

With bzlmod, you can use `archive_override` or `git_override`. For `WORKSPACE`, you modify the `http_archive` call; for example to use commit `abc123` with a `WORKSPACE` file:

1. Replace `url = "https://github.com/GoogleContainerTools/rules_distroless/releases/download/v0.1.0/rules_distroless-v0.1.0.tar.gz"`
   with a GitHub-provided source archive like `url = "https://github.com/GoogleContainerTools/rules_distroless/archive/abc123.tar.gz"`
1. Replace `strip_prefix = "rules_distroless-0.1.0"` with `strip_prefix = "rules_distroless-abc123"`
1. Update the `sha256`. The easiest way to do this is to comment out the line, then Bazel will
   print a message with the correct value.

> Note that GitHub source archives don't have a strong guarantee on the sha256 stability, see
> <https://github.blog/2023-02-21-update-on-the-future-stability-of-source-code-archives-and-hashes>

# Contributing

This ruleset is primarily funded to support [distroless](github.com/GoogleContainerTools/distroless). We may not work on feature requests that do not support this mission. We will however accept fully tested contributions via pull requests if they align with the project goals (ex. a different compression format) and may reject requests that do not (ex. supporting a non `deb` based packaging format).

# Adopters

- distroless: https://github.com/GoogleContainerTools/distroless

> An adopter? Add your company here by sending us a Pull Request.
