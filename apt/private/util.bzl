"utilities"

def _sanitize(str):
    return str.replace("+", "-p-").replace(":", "-").replace("~", "_")

def _get_repo_name(st):
    if st.find("+") != -1:
        return st.split("+")[-1]
    return st.split("~")[-1]

def _warning(rctx, message):
    rctx.execute([
        "echo",
        "\033[0;33mWARNING:\033[0m {}".format(message),
    ], quiet = False)

util = struct(
    sanitize = _sanitize,
    warning = _warning,
    get_repo_name = _get_repo_name,
)
