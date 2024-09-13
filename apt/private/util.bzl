"utilities"

def _get_dupes(list_):
    set_ = {}
    dupes = []

    for value in list_:
        if value in set_:
            dupes.append(value)
        set_[value] = True

    return dupes

def _sanitize(str):
    return str.replace("+", "-p-").replace(":", "-").replace("~", "_")

util = struct(
    sanitize = _sanitize,
    get_dupes = _get_dupes,
)
