"deb_import"

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# BUILD.bazel template
_DEB_IMPORT_BUILD_TMPL = '''
load("@rules_distroless//apt/private:deb_postfix.bzl", "deb_postfix")

deb_postfix(
    name = "data",
    srcs = glob(["data.tar*"]),
    outs = ["layer.tar.gz"],
    mergedusr = {},

    visibility = ["//visibility:public"],
)

filegroup(
    name = "control",
    srcs = glob(["control.tar.*"]),
    visibility = ["//visibility:public"],
)
'''

def deb_import(mergedusr = False, **kwargs):
    http_archive(
        build_file_content = _DEB_IMPORT_BUILD_TMPL.format(mergedusr),
        **kwargs
    )
