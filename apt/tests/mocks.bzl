"mocks for unit tests"

def _execute(arguments = None, **kwargs):
    return lambda *args, **kwargs: arguments.pop() if arguments else None

def _rctx(**kwargs):
    if "execute" not in kwargs:
        kwargs["execute"] = _execute([])
    return struct(**kwargs)

mock = struct(
    execute = _execute,
    rctx = _rctx,
)
