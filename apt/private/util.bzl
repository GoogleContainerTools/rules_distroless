"utilities"

load("@bazel_skylib//lib:sets.bzl", "sets")

def _escape(s):
    return s.replace("\\", "\\\\").replace("\n", "\\n")

def _get_dupes(list_):
    seen = sets.make()
    dupes = sets.make()

    for value in list_:
        if sets.contains(seen, value):
            sets.insert(dupes, value)
        sets.insert(seen, value)

    return sorted(sets.to_list(dupes))

def _parse_url(url):
    if "://" not in url:
        fail("Invalid URL: %s" % url)

    scheme, url_ = url.split("://", 1)

    path = "/"

    if "/" in url_:
        host, path_ = url_.split("/", 1)
        path += path_
    else:
        host = url_

    return struct(scheme = scheme, host = host, path = path)

def _sanitize(str):
    return str.replace("+", "-p-").replace(":", "-").replace("~", "_")

def _warning(rctx, message):
    rctx.execute([
        "echo",
        "\033[0;33mWARNING:\033[0m {}".format(message),
    ], quiet = False)

util = struct(
    escape = _escape,
    get_dupes = _get_dupes,
    parse_url = _parse_url,
    sanitize = _sanitize,
    warning = _warning,
)
