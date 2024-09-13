"apt-get"

load(":deb_import.bzl", "deb_packages", "package_arch_build")
load(":lockfile.bzl", "lockfile")

_BUILD_TMPL = """\
exports_files(glob(['packages.bzl']))

alias(
    name = "lock",
    actual = "@{}_resolve//:lock"
)
"""

def _deb_package_index_impl(rctx):
    lockf = lockfile.from_json(
        rctx,
        rctx.attr.lock_content or rctx.read(rctx.attr.lock),
    )
    lockf.write("lock.json")

    repo_prefix = "@" if rctx.attr.lock_content else ""
    repo_name = rctx.attr.name

    for architectures in lockf.packages.values():
        for package in architectures.values():
            rctx.file(
                "%s/%s/BUILD.bazel" % (package.name, package.arch),
                package_arch_build(
                    package,
                    repo_prefix,
                    repo_name,
                    rctx.read(rctx.attr.package_arch_build_template),
                ),
            )

    if rctx.attr.lock_content:
        packages_bzl = ""
    else:
        packages_bzl = deb_packages(repo_name, lockf.packages)

    rctx.file("packages.bzl", packages_bzl)
    rctx.file("BUILD.bazel", _BUILD_TMPL.format(rctx.attr.name.split("~")[-1]))

deb_package_index = repository_rule(
    implementation = _deb_package_index_impl,
    attrs = {
        "lock": attr.label(),
        "lock_content": attr.string(doc = "INTERNAL: DO NOT USE"),
        "package_template": attr.label(default = "//apt/private:package.BUILD.tmpl"),
        "package_arch_build_template": attr.label(default = "//apt/private:package_arch.BUILD.tmpl"),
    },
)
