"osrelease"

load("@aspect_bazel_lib//lib:expand_template.bzl", "expand_template")
load("@aspect_bazel_lib//lib:tar.bzl", "tar")
load("@aspect_bazel_lib//lib:utils.bzl", "propagate_common_rule_attributes")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

def os_release(name, content, path = "/usr/lib/os-release", **kwargs):
    """
    Create an Operating System Identification file from a key, value dictionary.

    https://www.freedesktop.org/software/systemd/man/latest/os-release.html

    Args:
        name: name of the target
        content: a key, value dictionary that will be serialized into `=` seperated lines.

            See https://www.freedesktop.org/software/systemd/man/latest/os-release.html#Options for well known keys.
        path: where to put the file in the result archive. default: `/usr/lib/os-release`
        **kwargs: other named arguments to expanded targets. see [common rule attributes](https://bazel.build/reference/be/common-definitions#common-attributes).
    """
    common_kwargs = propagate_common_rule_attributes(kwargs)
    write_file(
        name = "%s_content" % name,
        content = [
            "{}={}".format(key, value)
            for (key, value) in content.items()
        ] + [""],
        out = "%s.content" % name,
        **common_kwargs
    )

    # TODO: remove this expansion target once https://github.com/aspect-build/bazel-lib/issues/653 is fixed.
    expand_template(
        name = "%s_mtree" % name,
        out = "%s.mtree" % name,
        data = [":%s_content" % name],
        stamp = 0,
        template = [
            "#mtree",
            "%s uid=0 gid=0 mode=0755 time=0 type=file content={content}" % path.lstrip("/"),
            "",
        ],
        substitutions = {
            "{content}": "$(BINDIR)/$(rootpath :%s_content)" % name,
        },
        **common_kwargs
    )
    tar(
        name = name,
        srcs = [":%s_content" % name],
        mtree = ":%s_mtree" % name,
        **common_kwargs
    )
