"repository rule for resolving and generating lockfile"

load("@aspect_bazel_lib//lib:repo_utils.bzl", "repo_utils")
load(":lockfile.bzl", "lockfile")
load(":package_index.bzl", "package_index")
load(":package_resolution.bzl", "package_resolution")

_COPY_SH = """\
#!/usr/bin/env bash
set -o pipefail -o errexit -o nounset

lock=$(realpath $1)

cd $BUILD_WORKING_DIRECTORY

echo ''
echo 'Writing lockfile to {workspace_relative_path}' 
cp $lock {workspace_relative_path}

# Detect which file we wish the user to edit
if [ -e $BUILD_WORKSPACE_DIRECTORY/WORKSPACE ]; then
    wksp_file=WORKSPACE
elif [ -e $BUILD_WORKSPACE_DIRECTORY/WORKSPACE.bazel ]; then
    wksp_file=WORKSPACE.bazel
else
    echo>&2 "Error: neither WORKSPACE nor WORKSPACE.bazel file was found"
    exit 1
fi

# Detect a vendored buildozer binary in canonical location (tools/buildozer)
if [ -e $BUILD_WORKSPACE_DIRECTORY/tools/buildozer ]; then
    buildozer=tools/buildozer
else
    # Assume it's on the $PATH
    buildozer="npx @bazel/buildozer"
fi

if [[ "${{2:-}}" == "--autofix" ]]; then
    echo ''
    ${{buildozer}} 'set lock \"{label}\"' ${{wksp_file}}:{name}
else
    cat <<EOF
Run the following command to add the lockfile or pass --autofix flag to do it automatically.

   ${{buildozer}} 'set lock \"{label}\"' ${{wksp_file}}:{name}
EOF
fi
"""

def _parse_manifest(rctx):
    is_windows = repo_utils.is_windows(rctx)
    host_yq = Label("@{}_{}//:yq{}".format(rctx.attr.yq_toolchain_prefix, repo_utils.platform(rctx), ".exe" if is_windows else ""))
    yq_args = [
        str(rctx.path(host_yq)),
        str(rctx.path(rctx.attr.manifest)),
        "-o=json",
    ]
    result = rctx.execute(yq_args)
    if result.return_code:
        fail("failed to parse manifest yq. '{}' exited with {}: \nSTDOUT:\n{}\nSTDERR:\n{}".format(" ".join(yq_args), result.return_code, result.stdout, result.stderr))

    return json.decode(result.stdout if result.stdout != "null" else "{}")

def _deb_resolve_impl(rctx):
    manifest = _parse_manifest(rctx)

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
        for dep_constraint in manifest["packages"]:
            constraint = package_resolution.parse_depends(dep_constraint).pop()

            rctx.report_progress("Resolving %s" % dep_constraint)
            (package, dependencies, unmet_dependencies) = pkgresolution.resolve_all(
                name = constraint["name"],
                version = constraint["version"],
                arch = arch,
                include_transitive = rctx.attr.resolve_transitive,
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

    lockf.write("lock.json")

    locklabel = rctx.attr.manifest.relative(rctx.attr.manifest.name.replace(".yaml", ".lock.json"))

    rctx.file(
        "copy.sh",
        _COPY_SH.format(
            # TODO: don't assume the canonical -> apparent repo mapping character, as it might change
            # https://bazelbuild.slack.com/archives/C014RARENH0/p1719237766005439
            # https://github.com/bazelbuild/bazel/issues/22865
            name = rctx.name.removesuffix("_resolution").split("~")[-1],
            label = locklabel,
            workspace_relative_path = (("%s/" % locklabel.package) if locklabel.package else "") + locklabel.name,
        ),
        executable = True,
    )

    rctx.file("BUILD.bazel", """\
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
""")

deb_resolve = repository_rule(
    implementation = _deb_resolve_impl,
    attrs = {
        "manifest": attr.label(),
        "resolve_transitive": attr.bool(default = True),
        "yq_toolchain_prefix": attr.string(default = "yq"),
    },
)
