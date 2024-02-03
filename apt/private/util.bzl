"utilities"

def _set_dict(struct, value = None, keys = []):
    klen = len(keys)
    for i in range(klen - 1):
        k = keys[i]
        if not k in struct:
            struct[k] = {}
        struct = struct[k]

    struct[keys[-1]] = value

def _sanitize(str):
    return str.replace("+", "-p-").replace(":", "-")

util = struct(
    sanitize = _sanitize,
    set_dict = _set_dict,
)
