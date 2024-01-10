"oci runtime tarball"

load("@aspect_bazel_lib//lib:tar.bzl", "tar_lib")
load("@aspect_bazel_lib//lib:utils.bzl", "propagate_common_rule_attributes")
load("@bazel_skylib//lib:types.bzl", "types")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

def _mtree_line(dest, type, content = None, uid = "0", gid = "0", time = "0.0", mode = "0755"):
    # mtree expects paths to start with ./ so normalize paths that starts with
    # `/` or relative path (without / and ./)
    if not dest.startswith("."):
        if not dest.startswith("/"):
            dest = "/" + dest
        dest = "." + dest
    spec = [
        dest,
        "uid=" + uid,
        "gid=" + gid,
        "time=" + time,
        "mode=" + mode,
        "type=" + type,
    ]
    if content:
        spec.append("content=" + content)
    return " ".join(spec)

def _expand(file, expander):
    expanded = expander.expand(file)
    lines = []
    for e in expanded:
        path = e.tree_relative_path
        segments = path.split("/")
        for i in range(1, len(segments)):
            parent = "/".join(segments[:i])
            lines.append(_mtree_line(parent, "dir"))
        if path.startswith("blobs/"):
            path += ".tar.gz"
        lines.append(_mtree_line(path, "file", content = e.short_path))
    return lines

def _runtime_tarball_impl(ctx):
    bsdtar = ctx.toolchains[tar_lib.toolchain_type].tarinfo.binary
    jq = ctx.toolchains["@aspect_bazel_lib//lib:jq_toolchain_type"].jqinfo.bin

    mtree = ctx.actions.declare_file(ctx.attr.name + ".spec")
    content = ctx.actions.args()
    content.set_param_file_format("multiline")
    content.add("#mtree")
    content.add_all(
        ctx.files.image,
        map_each = _expand,
        expand_directories = True,
        uniquify = True,
    )
    ctx.actions.write(mtree, content = content)

    executable = ctx.actions.declare_file(ctx.attr.name + ".sh")
    ctx.actions.expand_template(
        template = ctx.file._oci_rt_tarball,
        output = executable,
        substitutions = {
            "{{bsdtar}}": bsdtar.short_path,
            "{{jq}}": jq.short_path,
            "{{image}}": ctx.file.image.short_path,
            "{{tags}}": ctx.file.repo_tags.short_path,
            "{{mtree}}": mtree.short_path,
        },
        is_executable = True,
    )

    runfiles = ctx.runfiles(files = [jq, bsdtar, mtree, ctx.file.image, ctx.file.repo_tags])

    return DefaultInfo(
        files = depset([mtree]),
        runfiles = runfiles,
        executable = executable,
    )

oci_rt_tarball_rule = rule(
    attrs = {
        "_oci_rt_tarball": attr.label(
            executable = True,
            allow_single_file = True,
            cfg = "exec",
            default = "//:oci_rt_tarball.sh",
        ),
        "image": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "repo_tags": attr.label(
            doc = """\
                a file containing repo_tags, one per line.
                """,
            allow_single_file = [".txt"],
            mandatory = True,
        ),
    },
    implementation = _runtime_tarball_impl,
    toolchains = [
        tar_lib.toolchain_type,
        "@aspect_bazel_lib//lib:jq_toolchain_type",
    ],
    executable = True,
)

def oci_rt_tarball(name, repo_tags = None, **kwargs):
    """Macro wrapper around [oci_tarball_rule](#oci_tarball_rule).

    Allows the repo_tags attribute to be a list of strings in addition to a text file.

    Args:
        name: name of resulting oci_tarball_rule
        repo_tags: a list of repository:tag to specify when loading the image,
            or a label of a file containing tags one-per-line.
            See [stamped_tags](https://github.com/bazel-contrib/rules_oci/blob/main/examples/push/stamp_tags.bzl)
            as one example of a way to produce such a file.
        **kwargs: other named arguments to [oci_tarball_rule](#oci_tarball_rule) and
            [common rule attributes](https://bazel.build/reference/be/common-definitions#common-attributes).
    """
    forwarded_kwargs = propagate_common_rule_attributes(kwargs)

    if types.is_list(repo_tags):
        tags_label = "_{}_write_tags".format(name)
        write_file(
            name = tags_label,
            out = "_{}.tags.txt".format(name),
            content = repo_tags,
            **forwarded_kwargs
        )
        repo_tags = tags_label

    oci_rt_tarball_rule(
        name = name,
        repo_tags = repo_tags,
        **kwargs
    )
