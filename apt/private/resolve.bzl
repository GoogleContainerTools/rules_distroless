"repository rule for resolving and generating lockfile"

load("@aspect_bazel_lib//lib:repo_utils.bzl", "repo_utils")
load(":lockfile.bzl", "lockfile")
load(":package_index.bzl", "package_index")
load(":package_resolution.bzl", "package_resolution")

def _parse_manifest(rctx, yq_toolchain_prefix, manifest):
    is_windows = repo_utils.is_windows(rctx)
    host_yq = Label("@{}_{}//:yq{}".format(yq_toolchain_prefix, repo_utils.platform(rctx), ".exe" if is_windows else ""))
    yq_args = [
        str(rctx.path(host_yq)),
        str(rctx.path(manifest)),
        "-o=json",
    ]
    result = rctx.execute(yq_args)
    if result.return_code:
        fail("failed to parse manifest yq. '{}' exited with {}: \nSTDOUT:\n{}\nSTDERR:\n{}".format(" ".join(yq_args), result.return_code, result.stdout, result.stderr))

    return json.decode(result.stdout if result.stdout != "null" else "{}")

# This function is shared between BZLMOD and WORKSPACE implementations.
# INTERNAL: DON NOT DEPEND!
# buildifier: disable=function-docstring-args
def internal_resolve(rctx, yq_toolchain_prefix, manifest, include_transitive):
    manifest = _parse_manifest(rctx, yq_toolchain_prefix, manifest)

    if manifest["version"] != 1:
        fail("Unsupported manifest version, {}. Please use `version: 1` manifest.".format(manifest["version"]))

    if type(manifest["sources"]) != "list":
        fail("`sources` should be an array")

    if type(manifest["archs"]) != "list":
        fail("`archs` should be an array")

    if type(manifest["packages"]) != "list":
        fail("`packages` should be an array")

    sources = []

    dist = None
    for src in manifest["sources"]:
        (distr, _, comp) = src["channel"].partition(" ")
        if not dist:
            dist = distr
        sources.append((
            src["url"],
            distr,
            comp,
        ))

    pkgindex = package_index.new(rctx, sources = sources, archs = manifest["archs"])
    pkgresolution = package_resolution.new(index = pkgindex)
    lockf = lockfile.empty(rctx)

    for arch in manifest["archs"]:
        dep_constraint_set = {}
        for dep_constraint in manifest["packages"]:
            if dep_constraint in dep_constraint_set:
                fail("Duplicate package, {}. Please remove it from your manifest".format(dep_constraint))
            dep_constraint_set[dep_constraint] = True

            constraint = package_resolution.parse_depends(dep_constraint).pop()

            rctx.report_progress("Resolving %s" % dep_constraint)
            (package, dependencies, unmet_dependencies) = pkgresolution.resolve_all(
                name = constraint["name"],
                version = constraint["version"],
                arch = arch,
                include_transitive = include_transitive,
            )

            if not package:
                fail("Unable to locate package `%s`" % dep_constraint)

            if len(unmet_dependencies):
                # buildifier: disable=print
                print("the following packages have unmet dependencies: %s" % ",".join([up[0] for up in unmet_dependencies]))

            lockf.add_package(package, arch)

            for dep in dependencies:
                lockf.add_package(dep, arch)
                lockf.add_package_dependency(package, dep, arch)
    return lockf

def _deb_resolve_impl(rctx):
    lockf = internal_resolve(rctx, rctx.attr.yq_toolchain_prefix, rctx.attr.manifest, rctx.attr.resolve_transitive)

    lockf.write("lock.json")

    rctx.file("BUILD.bazel", """\
filegroup(
    name = "lockfile",
    srcs = ["lock.json"],
    tags = ["manual"],
    visibility = ["//visibility:public"]
)
""")

deb_resolve = repository_rule(
    implementation = _deb_resolve_impl,
    attrs = {
        "manifest": attr.label(),
        "resolve_transitive": attr.bool(default = True),
        "yq_toolchain_prefix": attr.string(default = "yq"),
    },
)
