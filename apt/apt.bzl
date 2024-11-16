"""
`apt.install` macro

This documentation provides an overview of the convenience `apt.install`
repository macro to create Debian repositories with packages "installed" in
them and available to use in Bazel.
"""

load("//apt/private:index.bzl", _deb_package_index = "deb_package_index")
load("//apt/private:resolve.bzl", _deb_resolve = "deb_resolve")

def _apt_install(
        name,
        manifest,
        lock = None,
        nolock = False,
        package_template = None,
        resolve_transitive = True):
    """Repository macro to create Debian repositories.

    > [!WARNING]
    > THIS IS A LEGACY MACRO. Use it only if you are still using `WORKSPACE`.
    > Otherwise please use the [`apt` module extension](apt.md).

    Here's an example to create a Debian repo with `apt.install`:

    ```starlark
    # WORKSPACE

    load("@rules_distroless//apt:apt.bzl", "apt")

    apt.install(
        name = "bullseye",
        # lock = "//examples/apt:bullseye.lock.json",
        manifest = "//examples/apt:bullseye.yaml",
    )

    load("@bullseye//:packages.bzl", "bullseye_packages")
    bullseye_packages()
    ```

    Note that, for the initial setup (or if we want to run without a lock) the
    lockfile attribute can be omitted. All you need is a YAML
    [manifest](/examples/debian_snapshot/bullseye.yaml):
    ```yaml
    version: 1

    sources:
      - channel: bullseye main
        url: https://snapshot-cloudflare.debian.org/archive/debian/20240210T223313Z

    archs:
      - amd64

    packages:
      - perl
    ```

    `apt.install` will parse the manifest and will fetch and install the
    packages for the given architectures in the Bazel repo `@<NAME>`.

    Each `<PACKAGE>/<ARCH>` has two targets that match the usual structure of a
    Debian package: `data` and `control`.

    You can use the package like so: `@<REPO>//<PACKAGE>/<ARCH>:<TARGET>`.

    E.g. for the previous example, you could use `@bullseye//perl/amd64:data`.

    ### Lockfiles

    As mentioned, the macro can be used without a lock because the lock will be
    generated internally on-demand. However, this comes with the cost of
    performing a new package resolution on repository cache misses.

    The lockfile can be generated by running `bazel run @bullseye//:lock`. This
    will generate a `.lock.json` file of the same name and in the same path as
    the YAML `manifest` file.

    If you explicitly want to run without a lock and avoid the warning messages
    set the `nolock` argument to `True`.

    ### Best Practice: use snapshot archive URLs

    While we strongly encourage users to check in the generated lockfile, it's
    not always possible because Debian repositories are rolling by default.
    Therefore, a lockfile generated today might not work later if the upstream
    repository removes or publishes a new version of a package.

    To avoid this problems and increase the reproducibility it's recommended to
    avoid using normal Debian mirrors and use snapshot archives instead.

    Snapshot archives provide a way to access Debian package mirrors at a point
    in time. Basically, it's a "wayback machine" that allows access to (almost)
    all past and current packages based on dates and version numbers.

    Debian has had snapshot archives for [10+
    years](https://lists.debian.org/debian-announce/2010/msg00002.html). Ubuntu
    began providing a similar service recently and has packages available since
    March 1st 2023.

    To use this services simply use a snapshot URL in the manifest. Here's two
    examples showing how to do this for Debian and Ubuntu:
      * [/examples/debian_snapshot](/examples/debian_snapshot)
      * [/examples/ubuntu_snapshot](/examples/ubuntu_snapshot)

    For more infomation, please check https://snapshot.debian.org and/or
    https://snapshot.ubuntu.com.

    Args:
        name: name of the repository
        manifest: label to a `manifest.yaml`
        lock: label to a `lock.json`
        nolock: bool, set to True if you explicitly want to run without a lock
                and avoid the DEBUG messages.
        package_template: (EXPERIMENTAL!) a template file for generated BUILD
                          files. Available template replacement keys are:
                          `{target_name}`, `{deps}`, `{urls}`, `{name}`,
                          `{arch}`, `{sha256}`, `{repo_name}`
        resolve_transitive: whether dependencies of dependencies should be
                            resolved and added to the lockfile.
    """
    _deb_resolve(
        name = name + "_resolve",
        manifest = manifest,
        resolve_transitive = resolve_transitive,
    )

    if not lock and not nolock:
        # buildifier: disable=print
        print("\nNo lockfile was given, please run `bazel run @%s//:lock` to create the lockfile." % name)

    _deb_package_index(
        name = name,
        lock = lock if lock else "@" + name + "_resolve//:lock.json",
        package_template = package_template,
    )

apt = struct(
    install = _apt_install,
)
