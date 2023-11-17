"jks"

load(":tar.bzl", "tar_lib")

_DOC = """Create a java keystore (database) of cryptographic keys, X.509 certificate chains, and trusted certificates.

Currently only public  X.509 are supported as part of the PUBLIC API contract.
"""

def _find_keytool(java_runtime):
    for f in java_runtime.files.to_list():
        if f.basename == "keytool":
            return f
    fail("java toolchain does not contain `keytool`.")

def _java_keystore_impl(ctx):
    jdk = ctx.toolchains["@bazel_tools//tools/jdk:runtime_toolchain_type"]
    coreutils = ctx.toolchains["@aspect_bazel_lib//lib:coreutils_toolchain_type"]
    bsdtar = ctx.toolchains[tar_lib.TOOLCHAIN_TYPE]
    keytool = _find_keytool(jdk.java_runtime)

    jks = ctx.actions.declare_file(ctx.attr.name + ".jks")

    args = ctx.actions.args()

    args.add(bsdtar.tarinfo.binary)
    args.add(keytool)
    args.add(coreutils.coreutils_info.bin)
    args.add(jks)
    args.add_all(ctx.files.certificates)

    ctx.actions.run(
        executable = ctx.executable._java_keystore_sh,
        tools = depset(
            [keytool, coreutils.coreutils_info.bin],
            transitive = [bsdtar.default.files],
        ),
        inputs = ctx.files.certificates,
        outputs = [jks],
        arguments = [args],
    )

    output = ctx.actions.declare_file(ctx.attr.name + ".tar.gz")
    mtree = tar_lib.create_mtree(ctx)
    mtree.add_file_with_parents("/etc/ssl/certs/java/cacerts", jks)
    mtree.build(output = output, mnemonic = "JavaKeyStore", inputs = [jks])

    return [
        DefaultInfo(files = depset([output])),
        OutputGroupInfo(
            jks = depset([jks]),
        ),
    ]

java_keystore = rule(
    doc = _DOC,
    attrs = {
        "_java_keystore_sh": attr.label(
            allow_single_file = True,
            executable = True,
            cfg = "exec",
            default = ":java_keystore.sh",
        ),
        "certificates": attr.label_list(
            allow_files = True,
            mandatory = True,
            allow_empty = False,
        ),
    },
    implementation = _java_keystore_impl,
    toolchains = [
        tar_lib.TOOLCHAIN_TYPE,
        "@bazel_tools//tools/jdk:runtime_toolchain_type",
        "@aspect_bazel_lib//lib:coreutils_toolchain_type",
    ],
)
