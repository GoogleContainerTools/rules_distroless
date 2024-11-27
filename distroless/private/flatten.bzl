"flatten"

load(":tar.bzl", "tar_lib")

_DOC = """Flatten multiple archives into single archive."""

def _flatten_impl(ctx):
    bsdtar = ctx.toolchains[tar_lib.TOOLCHAIN_TYPE]

    ext = tar_lib.common.compression_to_extension[ctx.attr.compress] if ctx.attr.compress else ".tar"
    output = ctx.actions.declare_file(ctx.attr.name + ext)

    args = ctx.actions.args()
    args.add(bsdtar.tarinfo.binary)
    args.add(output if ctx.attr.deduplicate else "-")
    args.add_all(tar_lib.DEFAULT_ARGS)
    args.add("--create")
    tar_lib.common.add_compression_args(ctx.attr.compress, args)
    tar_lib.add_default_compression_args(ctx.attr.compress, args)
    args.add("--file", "-" if ctx.attr.deduplicate else output)
    args.add_all(ctx.files.tars, format_each = "@%s")

    ctx.actions.run(
        executable = ctx.executable._flatten_sh,
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
        "deduplicate": attr.bool(doc = """\
EXPERIMENTAL: Remove duplicate entries from the archives after flattening.
        
This requires `awk`, `sort` and `tar` to be available in the PATH.

To support macOS, presence of `gtar` is checked, and `tar` if it does not exist, 
and ensured if supports the `--delete` mode.

On macOS: `brew install gnu-tar` can be run to install gnutar.
See: https://formulae.brew.sh/formula/gnu-tar

NOTE: You may also need to run `sudo ln -s /opt/homebrew/bin/gtar /usr/local/bin/gtar` to make it available to Bazel.
        """, default = False),
        "compress": attr.string(
            doc = "Compress the archive file with a supported algorithm.",
            values = tar_lib.common.accepted_compression_types,
        ),
        "_flatten_sh": attr.label(default = "//distroless/private:flatten.sh", executable = True, cfg = "exec", allow_single_file = True),
    },
    implementation = _flatten_impl,
    toolchains = [tar_lib.TOOLCHAIN_TYPE],
)
