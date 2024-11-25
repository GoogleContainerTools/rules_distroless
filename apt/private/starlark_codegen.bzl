"Starlark codegen"

load("//apt/private:util.bzl", "util")

_BRACKETS = {
    "open": {
        "list": "[",
        "tuple": "(",
        "dict": "{",
    },
    "close": {
        "list": "]",
        "tuple": ")",
        "dict": "}",
    },
}

_ITERATION_MAX_ = 1 << 31 - 1

def _gen(
        value,
        indent = True,
        indent_count = 0,
        indent_size = 4,
        quote_strings = True,
        quote_keys = True):
    result = []

    stack = [(value, type(value), None)]

    for i in range(_ITERATION_MAX_):
        if not stack:
            break

        if i == _ITERATION_MAX_:
            msg = "Reached _ITERATION_MAX_ trying to codegen: %s"
            fail(msg % value)

        current, current_type, context = stack.pop()

        if current_type in ("NoneType", "int", "float", "bool"):
            result.append(str(current))

        elif current_type == "string":
            v = util.escape(current)
            result.append('"%s"' % v if quote_strings else v)

        elif current_type in ("list", "tuple", "dict"):
            if context == None and not current:
                # special empty case:
                result.append(_BRACKETS["open"][current_type])
                result.append(_BRACKETS["close"][current_type])

            elif context == None and current:
                kind = current_type

                if current_type == "dict":
                    current = current.items()

                result.append(_BRACKETS["open"][current_type])

                if indent:
                    indent_count += 1

                stack.append((None, current_type, "close"))

                items = [(item, current_type, "item") for item in current]
                stack.extend(reversed(items))

            elif context == "item":
                kind = current_type.split("_")[0]

                if result[-1] != _BRACKETS["open"][current_type]:
                    result.append(",\n" if indent else ", ")
                elif indent:
                    result.append("\n")

                if current_type == "dict":
                    k, v = current

                    if indent:
                        tab = " " * indent_size
                        result.append(tab * indent_count)

                    k = '"%s"' % str(k) if quote_keys else str(k)
                    result.append("%s: " % k)

                    current = v
                elif indent and result[-1] != _BRACKETS["open"][current_type]:
                    tab = " " * indent_size
                    result.append(tab * indent_count)

                stack.append((current, type(current), None))

            elif context == "close":
                if indent:
                    result.append(",\n")
                    indent_count -= 1

                    tab = " " * indent_size
                    result.append(tab * indent_count)

                kind = current_type.split("_")[0]
                result.append(_BRACKETS["close"][current_type])

        else:
            fail("Unsupported type: %s" % current_type)

    return "".join(result)

starlark = struct(
    gen = _gen,
    igen = lambda value, **kwargs: _gen(value, indent = False, **kwargs),
)
