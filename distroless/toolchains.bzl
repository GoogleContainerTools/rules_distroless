"macro for registering toolchains required"

load("@aspect_bazel_lib//lib:repositories.bzl", "register_expand_template_toolchains", "register_tar_toolchains", "register_zstd_toolchains")

def distroless_register_toolchains():
    register_zstd_toolchains()
    register_tar_toolchains()
    register_expand_template_toolchains()
