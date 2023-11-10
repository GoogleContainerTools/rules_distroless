"cacerts"

load(":tar.bzl", "tar_lib")

_DOC = """Create a ca-certificates.crt bundle from Common CA certificates.

When provided with the `ca-certificates` Debian package it will create a bundle
of all common CA certificates at `/usr/share/ca-certificates` and bundle them into
a `ca-certificates.crt` file at `/etc/ssl/certs/ca-certificates.crt`

An example of this would be

```starlark
# MODULE.bazel
http_archive = use_repo_rule("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "ca-certificates",
    type = ".deb",
    canonical_id = "test",
    sha256 = "b2d488ad4d8d8adb3ba319fc9cb2cf9909fc42cb82ad239a26c570a2e749c389",
    urls = ["https://snapshot.debian.org/archive/debian/20231106T210201Z/pool/main/c/ca-certificates/ca-certificates_20210119_all.deb"],
    build_file_content = "exports_files(["data.tar.xz"])"
)

# BUILD.bazel
load("@rules_distroless//distroless:defs.bzl", "cacerts")

cacerts(
    name = "example",
    package = "@ca-certificates//:data.tar.xz",
)
```
"""

def _cacerts_impl(ctx):
    bsdtar = ctx.toolchains[tar_lib.TOOLCHAIN_TYPE]

    cacerts = ctx.actions.declare_file(ctx.attr.name + ".crt")
    copyright = ctx.actions.declare_file(ctx.attr.name + ".copyright")
    ctx.actions.run(
        executable = ctx.executable._cacerts_sh,
        inputs = [ctx.file.package],
        outputs = [cacerts, copyright],
        tools = bsdtar.default.files,
        arguments = [
            bsdtar.tarinfo.binary.path,
            ctx.file.package.path,
            cacerts.path,
            copyright.path,
        ],
    )

    output = ctx.actions.declare_file(ctx.attr.name + ".tar.gz")
    mtree = tar_lib.create_mtree(ctx)
    mtree.add_file_with_parents("/etc/ssl/certs/ca-certificates.crt", cacerts)
    mtree.add_file_with_parents("/usr/share/doc/ca-certificates/copyright", copyright)
    mtree.build(output = output, mnemonic = "CaCertsTarGz", inputs = [cacerts, copyright])

    return [
        DefaultInfo(files = depset([output])),
    ]

cacerts = rule(
    doc = _DOC,
    attrs = {
        "_cacerts_sh": attr.label(
            allow_single_file = True,
            executable = True,
            cfg = "exec",
            default = ":cacerts.sh",
        ),
        "package": attr.label(
            allow_single_file = [".tar.xz", ".tar.gz", ".tar"],
            mandatory = True,
        ),
    },
    implementation = _cacerts_impl,
    toolchains = [tar_lib.TOOLCHAIN_TYPE],
)
