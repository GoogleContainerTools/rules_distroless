"mtree helpers"

BSDTAR_TOOLCHAIN = "@aspect_bazel_lib//lib:tar_toolchain_type"

def _mtree_line(file, type, content = None, uid = "0", gid = "0", time = "1672560000", mode = "0755"):
    spec = [
        file,
        "uid=" + uid,
        "gid=" + gid,
        "time=" + time,
        "mode=" + mode,
        "type=" + type,
    ]
    if content:
        spec.append("content=" + content)
    return " ".join(spec)

def _add_parents(path, uid = "0", gid = "0", time = "1672560000", mode = "0755"):
    lines = []
    segments = path.split("/")
    segments.pop()
    for i in range(0, len(segments)):
        parent = "/".join(segments[:i + 1])
        if not parent or parent == ".":
            continue
        lines.append(
            _mtree_line(parent.lstrip("/"), "dir", uid = uid, gid = gid, time = time, mode = mode),
        )
    return lines

def _add_file_with_parents(path, file):
    lines = _add_parents(path)
    lines.append(_mtree_line(path.lstrip("/"), "file", content = file.path))
    return lines

def _add_directory_with_parents(path, **kwargs):
    lines = _add_parents(path)
    lines.append(_mtree_line(path.lstrip("/"), "dir", **kwargs))
    return lines

def _build_tar(ctx, mtree, output, inputs = [], compression = "gzip", mnemonic = "Tar"):
    bsdtar = ctx.toolchains[BSDTAR_TOOLCHAIN]

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
    create_mtree = _create_mtree,
    line = _mtree_line,
    add_directory_with_parents = _add_directory_with_parents,
    add_file_with_parents = _add_file_with_parents,
    TOOLCHAIN_TYPE = BSDTAR_TOOLCHAIN,
)
