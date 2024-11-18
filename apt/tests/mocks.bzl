"mocks for unit tests"

URL = "http://nowhere"

def _execute(arguments = None, **kwargs):
    return lambda *args, **kwargs: arguments.pop() if arguments else None

def _report_progress():
    return lambda msg: None

def _read(read_output = None):
    return lambda filename: read_output

def _download(success):
    return lambda *args, **kwargs: struct(success = success)

def _rctx(**kwargs):
    if "execute" not in kwargs:
        kwargs["execute"] = _execute([])

    if "report_progress" not in kwargs:
        kwargs["report_progress"] = _report_progress()

    return struct(**kwargs)

def _pkg(package, **kwargs):
    defaults = {
        "Package": package,
        "Root": URL,
    }

    pkg = {k.title().replace("_", "-"): v for k, v in kwargs.items()}

    return defaults | pkg

def _pkg_index(pkg):
    return "\n".join([
        "{}: {}".format(k, v)
        for k, v in pkg.items()
    ]) + "\n\n"

def _packages_index_content(*pkgs):
    return "".join([_pkg_index(pkg) for pkg in pkgs])

mock = struct(
    URL = URL,
    execute = _execute,
    rctx = _rctx,
    report_progress = _report_progress,
    read = _read,
    download = _download,
    pkg = _pkg,
    pkg_index = _pkg_index,
    packages_index_content = _packages_index_content,
)
