"flatten"

load(":tar.bzl", "tar_lib")

_DOC = """Flatten multiple archives into single archive."""

def _flatten_impl(ctx):
    bsdtar = ctx.toolchains[tar_lib.TOOLCHAIN_TYPE]

    ext = tar_lib.common.compression_to_extension[ctx.attr.compression] if ctx.attr.compression else ".tar"
    output = ctx.actions.declare_file(ctx.attr.name + ext)

    args = ctx.actions.args()
    args.add("--create")
    tar_lib.common.add_compression_args(ctx.attr.compression, args)
    args.add("--file", output)
    args.add_all(ctx.files.tars, format_each = "@%s")

    ctx.actions.run(
        executable = bsdtar.tarinfo.binary,
        inputs = ctx.files.tars,
        outputs = [output],
        tools = bsdtar.default.files,
        arguments = [args],
    )

    return [
        DefaultInfo(files = depset([output])),
    ]

flatten = rule(
    doc = _DOC,
    attrs = {
        "tars": attr.label_list(
            allow_files = tar_lib.common.accepted_tar_extensions,
            mandatory = True,
            allow_empty = False,
            doc = "List of tars to flatten",
        ),
        "compression": attr.string(
            doc = "Compress the archive file with a supported algorithm.",
            values = tar_lib.common.accepted_compression_types,
        ),
    },
    implementation = _flatten_impl,
    toolchains = [tar_lib.TOOLCHAIN_TYPE],
)
