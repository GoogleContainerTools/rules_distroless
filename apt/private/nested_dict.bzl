"nested dict"

def _set(store, keys, value, add = False):
    for key in keys[:-1]:
        if key not in store:
            store[key] = {}
        store = store[key]

    if add:
        if keys[-1] not in store:
            store[keys[-1]] = []

        store[keys[-1]].append(value)
    else:
        store[keys[-1]] = value

def _get(store, keys, default_value):
    if not keys:
        return default_value

    value = store

    for k in keys:
        if k in value:
            value = value[k]
        else:
            value = default_value
            break

    return value

def _new():
    store = {}

    return struct(
        set = lambda keys, value: _set(store, keys, value),
        add = lambda keys, value: _set(store, keys, value, add = True),
        get = lambda keys, default_value = None: _get(store, keys, default_value),
        has = lambda keys: _get(store, keys, default_value = None) != None,
        clear = lambda: store.clear(),
        values = lambda: store.values(),
        as_dict = lambda: store,
    )

nested_dict = struct(
    new = _new,
)
