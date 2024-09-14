"utilities"

def _sanitize(str):
    return str.replace("+", "-p-").replace(":", "-").replace("~", "_")

util = struct(
    sanitize = _sanitize,
)
