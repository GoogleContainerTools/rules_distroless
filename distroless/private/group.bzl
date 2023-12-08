"osrelease"

load("@aspect_bazel_lib//lib:expand_template.bzl", "expand_template")
load("@aspect_bazel_lib//lib:tar.bzl", "tar")
load("@aspect_bazel_lib//lib:utils.bzl", "propagate_common_rule_attributes")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

def group(name, groups, **kwargs):
    """
    Create a group file from array of dicts.

    https://www.ibm.com/docs/en/aix/7.2?topic=files-etcgroup-file#group_security__a21597b8__title__1

    Args:
        name: name of the target
        groups: an array of dicts which will be serialized into single group file.
        **kwargs: other named arguments to expanded targets. see [common rule attributes](https://bazel.build/reference/be/common-definitions#common-attributes).
    """
    common_kwargs = propagate_common_rule_attributes(kwargs)
    write_file(
        name = "%s_content" % name,
        content = [
            # See https://www.ibm.com/docs/en/aix/7.2?topic=files-etcgroup-file#group_security__a3179518__title__1
            ":".join([
                entry["name"],
                "!",  # not used. Group administrators are provided instead of group passwords.
                str(entry["gid"]),
                ",".join(entry["users"]),
            ])
            for entry in groups
        ],
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
            "etc/group uid=0 gid=0 mode=0644 time=0.0 type=file content={content}",
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
