"utilities"

def _get_dupes(list_):
    set_ = {}
    dupes = []

    for value in list_:
        if value in set_:
            dupes.append(value)
        set_[value] = True

    return dupes

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

util = struct(
    get_dupes = _get_dupes,
    parse_url = _parse_url,
    sanitize = _sanitize,
)
