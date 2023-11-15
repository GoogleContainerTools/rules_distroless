"osrelease"

load("@aspect_bazel_lib//lib:expand_template.bzl", "expand_template")
load("@aspect_bazel_lib//lib:tar.bzl", "tar")
load("@aspect_bazel_lib//lib:utils.bzl", "propagate_common_rule_attributes")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

def passwd(name, passwds, **kwargs):
    """
    Create a passwd file from array of dicts.

    https://www.ibm.com/docs/en/aix/7.3?topic=passwords-using-etcpasswd-file

    Args:
        name: name of the target
        passwds: an array of dicts which will be serialized into single passwd file.

            An example;

            ```
            dict(gid = 0, uid = 0, home = "/root", shell = "/bin/bash", username = "root")
            ```
        **kwargs: other named arguments to expanded targets. see [common rule attributes](https://bazel.build/reference/be/common-definitions#common-attributes).
    """
    common_kwargs = propagate_common_rule_attributes(kwargs)
    write_file(
        name = "%s_content" % name,
        content = [
            # See: https://www.ibm.com/docs/kk/aix/7.2?topic=files-etcpasswd-file#passwd_security__a21597b8__title__1
            ":".join([
                entry["username"],
                entry.pop("password", "!"),
                str(entry["uid"]),
                str(entry["gid"]),
                ",".join(entry.pop("gecos", [])),
                entry["home"],
                entry["shell"],
            ])
            for entry in passwds
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
            "etc/passwd uid=0 gid=0 mode=0700 time=0 type=file content={content}",
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
