"dpkg_info"

# buildifier: disable=bzl-visibility
load("//distroless/private:tar.bzl", "tar_lib")

_DOC = """TODO: docs"""

def _dpkg_info_impl(ctx):
    bsdtar = ctx.toolchains[tar_lib.TOOLCHAIN_TYPE]

    ext = tar_lib.common.compression_to_extension[ctx.attr.compression] if ctx.attr.compression else ".tar"
    output = ctx.actions.declare_file(ctx.attr.name + ext)

    args = ctx.actions.args()
    args.add(bsdtar.tarinfo.binary)
    args.add(output)
    args.add(ctx.file.control)
    args.add(ctx.file.data)
    args.add(ctx.attr.package_name)
    tar_lib.common.add_compression_args(ctx.attr.compression, args)

    ctx.actions.run(
        executable = ctx.executable._dpkg_info_sh,
        inputs = [ctx.file.control, ctx.file.data],
        outputs = [output],
        tools = bsdtar.default.files,
        arguments = [args],
    )

    return [
        DefaultInfo(files = depset([output])),
    ]

dpkg_info = rule(
    doc = _DOC,
    attrs = {
        "_dpkg_info_sh": attr.label(
            allow_single_file = True,
            executable = True,
            cfg = "exec",
            default = ":dpkg_info.sh",
        ),
        "package_name": attr.string(mandatory = True),
        "control": attr.label(
            allow_single_file = [".tar.zst", ".tar.xz", ".tar.gz", ".tar"],
            mandatory = True,
        ),
        "data": attr.label(
            allow_single_file = [".tar.zst", ".tar.xz", ".tar.gz", ".tar"],
            mandatory = True,
        ),
        "compression": attr.string(
            doc = "Compress the archive file with a supported algorithm.",
            values = tar_lib.common.accepted_compression_types,
        ),
    },
    implementation = _dpkg_info_impl,
    toolchains = [tar_lib.TOOLCHAIN_TYPE],
)