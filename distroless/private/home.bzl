"home"

load("@aspect_bazel_lib//lib:tar.bzl", "tar")
load(":tar.bzl", "tar_lib")

def home(name, dirs, **kwargs):
    """
    Create home directories with specific uid and gids.

    Args:
        name: name of the target
        dirs: an array of dicts
        **kwargs: other named arguments to that is passed to tar. see [common rule attributes](https://bazel.build/reference/be/common-definitions#common-attributes).
    """
    mtree = []

    for home in dirs:
        mtree.extend(
            tar_lib.add_directory_with_parents(home["home"], uid = str(home["uid"]), gid = str(home["gid"])),
        )

    tar(
        name = name,
        srcs = [],
        mtree = mtree,
        **kwargs
    )
