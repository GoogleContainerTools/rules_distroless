"deb_import"

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# BUILD.bazel template
_DEB_IMPORT_BUILD_TMPL = """
# TODO: https://github.com/bazel-contrib/rules_oci/pull/523
_RECOMPRESS_CMD = "$(ZSTD_BIN) -f --decompress $< --stdout | $(ZSTD_BIN) - --format=gzip >$@"
genrule(
    name = "data",
    srcs = glob(["data.tar.*"]),
    outs = ["data.tar.gz"],
    cmd = _RECOMPRESS_CMD,
    toolchains = ["@zstd_toolchains//:resolved_toolchain"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "control",
    srcs = glob(["control.tar.*"]),
    visibility = ["//visibility:public"],
)
"""

def deb_import(**kwargs):
    http_archive(
        build_file_content = _DEB_IMPORT_BUILD_TMPL,
        **kwargs
    )
