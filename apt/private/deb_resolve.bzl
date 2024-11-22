"repository rule for resolving and generating lockfile"

load("@aspect_bazel_lib//lib:repo_utils.bzl", "repo_utils")
load(":apt_deb_repository.bzl", "deb_repository")
load(":apt_dep_resolver.bzl", "dependency_resolver")
load(":lockfile.bzl", "lockfile")
load(":manifest.bzl", "manifest")
load(":version_constraint.bzl", "version_constraint")

_BUILD_TMPL = """
filegroup(
    name = "lockfile",
    srcs = ["lock.json"],
    tags = ["manual"],
    visibility = ["//visibility:public"]
)

sh_binary(
    name = "lock",
    srcs = ["copy.sh"],
    data = ["lock.json"],
    tags = ["manual"],
    args = ["$(location :lock.json)"],
    visibility = ["//visibility:public"]
) 
"""

def _deb_resolve_impl(rctx):
    lockf = manifest.lock(rctx, rctx.attr.manifest, rctx.attr.resolve_transitive)
    lockf.write("lock.json")

    lock_filename = rctx.attr.manifest.name.replace(".yaml", ".lock.json")
    lock_label = rctx.attr.manifest.relative(lock_filename)
    workspace_relative_path = "{}{}".format(
        ("%s/" % lock_label.package) if lock_label.package else "",
        lock_label.name,
    )

    rctx.file(
        "copy.sh",
        rctx.read(rctx.attr._copy_sh_tmpl).format(
            # NOTE: the split("~") is needed when we run bazel from another
            # directory, e.g. when running e2e tests we change dir to e2e/smoke
            # and then rctx.name is 'rules_distroless~~apt~bullseye'
            repo_name = rctx.name.split("~")[-1].replace("_resolve", ""),
            lock_label = lock_label,
            workspace_relative_path = workspace_relative_path,
        ),
        executable = True,
    )

    rctx.file("BUILD.bazel", _BUILD_TMPL)

deb_resolve = repository_rule(
    implementation = _deb_resolve_impl,
    attrs = {
        "manifest": attr.label(),
        "resolve_transitive": attr.bool(default = True),
        "yq_toolchain_prefix": attr.string(default = "yq"),
        "_copy_sh_tmpl": attr.label(
            default = "//apt/private:copy.sh.tmpl",
            doc = "INTERNAL, DO NOT USE - " +
                  "private attribute label to prevent repo restart",
        ),
    },
)
