"mtree helpers"

load("@aspect_bazel_lib//lib:tar.bzl", tar = "tar_lib")

DEFAULT_GID = "0"
DEFAULT_UID = "0"
DEFAULT_TIME = "0.0"
DEFAULT_MODE = "0755"

def _mtree_line(dest, type, content = None, uid = DEFAULT_UID, gid = DEFAULT_GID, time = DEFAULT_TIME, mode = DEFAULT_MODE):
    # mtree expects paths to start with ./ so normalize paths that starts with
    # `/` or relative path (without / and ./)
    if not dest.startswith("."):
        if not dest.startswith("/"):
            dest = "/" + dest
        dest = "." + dest
    spec = [
        dest,
        "uid=" + uid,
        "gid=" + gid,
        "time=" + time,
        "mode=" + mode,
        "type=" + type,
    ]
    if content:
        spec.append("content=" + content)
    return " ".join(spec)

def _add_parents(path, uid = DEFAULT_UID, gid = DEFAULT_GID, time = DEFAULT_TIME, mode = DEFAULT_MODE):
    lines = []
    segments = path.split("/")
    segments.pop()
    for i in range(0, len(segments)):
        parent = "/".join(segments[:i + 1])
        if not parent:
            continue
        lines.append(
            _mtree_line(parent, "dir", uid = uid, gid = gid, time = time, mode = mode),
        )
    return lines

def _add_file_with_parents(path, file):
    lines = _add_parents(path)
    lines.append(_mtree_line(path, "file", content = file.path))
    return lines

def _add_directory_with_parents(path, **kwargs):
    lines = _add_parents(path, **kwargs)
    lines.append(_mtree_line(path, "dir", **kwargs))
    return lines

def _build_tar(ctx, mtree, output, inputs = [], compression = "gzip", mnemonic = "Tar"):
    bsdtar = ctx.toolchains[tar.toolchain_type]

    inputs = inputs[:]
    inputs.append(mtree)

    args = ctx.actions.args()
    args.add("--create")
    args.add(compression, format = "--%s")
    args.add("--file", output)
    args.add(mtree, format = "@%s")

    ctx.actions.run(
        executable = bsdtar.tarinfo.binary,
        inputs = inputs,
        outputs = [output],
        tools = bsdtar.default.files,
        arguments = [args],
        mnemonic = mnemonic,
    )

def _build_mtree(ctx, content):
    mtree_out = ctx.actions.declare_file(ctx.label.name + ".spec")
    ctx.actions.write(mtree_out, content = content)
    return mtree_out

def _create_mtree(ctx):
    content = ctx.actions.args()
    content.set_param_file_format("multiline")
    content.add("#mtree")
    return struct(
        line = lambda **kwargs: content.add(_mtree_line(**kwargs)),
        add_file_with_parents = lambda *args, **kwargs: content.add_all(_add_file_with_parents(*args), uniquify = kwargs.pop("uniqify", True)),
        add_parents = lambda *args, **kwargs: content.add_all(_add_parents(*args), uniquify = kwargs.pop("uniqify", True)),
        build = lambda **kwargs: _build_tar(ctx, _build_mtree(ctx, content), **kwargs),
        build_mtree = lambda **kwargs: _build_mtree(ctx, content),
    )

tar_lib = struct(
    TOOLCHAIN_TYPE = tar.toolchain_type,
    create_mtree = _create_mtree,
    mtree = struct(
        line = _mtree_line,
        add_directory_with_parents = _add_directory_with_parents,
        add_file_with_parents = _add_file_with_parents,
    ),
    common = tar.common,
)
