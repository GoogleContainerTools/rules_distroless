"deb_import"

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# BUILD.bazel template
_DEB_IMPORT_BUILD_TMPL = '''
genrule(
    name = "data",
    srcs = glob(["data.tar*"]),
    outs = ["layer.tar.gz"],
    cmd = """
    # Per the dpkg-dev man page:
    # https://manpages.debian.org/bookworm/dpkg-dev/deb.5.en.html
    #
    # Debian data.tar files can be:
    #  - .tar uncompressed, supported since dpkg 1.10.24
    #  - .tar compressed with
    #    *  gzip: .gz
    #    * bzip2: .bz2, supported since dpkg 1.10.24
    #    *  lzma: .lzma, supported since dpkg 1.13.25
    #    *    xz: .xz, supported since dpkg 1.15.6
    #    *  zstd: .zst, supported since dpkg 1.21.18
    #
    # ZSTD_BIN can decompress all formats except bzip2
    #
    # The OCI image spec supports .tar and .tar compressed with gzip or zstd.
    # Bazel needs the output filename to be fixed in advanced so we settle for
    # gzip compression.

    data_file="$<"
    layer="$@"

    case "$$data_file" in
        *data.tar.gz)
            mv "$$data_file" "$$layer"
        ;;
        *data.tar)
            $(ZSTD_BIN) --compress --format=gzip "$$data_file" > "$$layer"
        ;;
        *data.tar.xz|*data.tar.zst|*data.tar.lzma)
            $(ZSTD_BIN) --force --decompress --stdout "$$data_file" |
            $(ZSTD_BIN) --compress --format=gzip - > "$$layer"
        ;;
        *)
            echo "ERROR: data file not supported: $$data_file"
            exit 1
        ;;
    esac
    """,
    toolchains = ["@zstd_toolchains//:resolved_toolchain"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "control",
    srcs = glob(["control.tar.*"]),
    visibility = ["//visibility:public"],
)
'''

def deb_import(**kwargs):
    http_archive(
        build_file_content = _DEB_IMPORT_BUILD_TMPL,
        **kwargs
    )
