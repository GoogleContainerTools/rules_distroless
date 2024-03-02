"util"

def _get_attr(o, k, d = None):
    if k in o:
        return o[k]
    if hasattr(o, k):
        return getattr(o, k)
    if d != None:
        return d
    fail("missing key %s" % k)

util = struct(
    get_attr = _get_attr,
)
