"utilities"

load("@bazel_skylib//lib:sets.bzl", "sets")

def _get_dupes(list_):
    seen = sets.make()
    dupes = sets.make()

    for value in list_:
        if sets.contains(seen, value):
            sets.insert(dupes, value)
        sets.insert(seen, value)

    return sorted(sets.to_list(dupes))

def _sanitize(str):
    return str.replace("+", "-p-").replace(":", "-").replace("~", "_")

def _warning(rctx, message):
    rctx.execute([
        "echo",
        "\033[0;33mWARNING:\033[0m {}".format(message),
    ], quiet = False)

util = struct(
    get_dupes = _get_dupes,
    sanitize = _sanitize,
    warning = _warning,
)
