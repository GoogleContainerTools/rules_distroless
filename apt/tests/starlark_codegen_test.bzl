"unit tests for Starlark codegen utils"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apt/private:starlark_codegen.bzl", "starlark")

_TEST_SUITE_PREFIX = "starlark_codegen/"

_DICT = {
    "key": [1, 2, {"a": 1}],
    "flag": True,
    "name": "example",
    42: None,
    "a": "{foo}",
}

def _serialize_indent_test(ctx):
    env = unittest.begin(ctx)

    expected = """
   {
      "key": [
         1,
         2,
         {
            "a": 1,
         },
      ],
      "flag": True,
      "name": "example",
      "42": None,
      "a": "{foo}",
   }
    """.strip()
    actual = starlark.gen(_DICT, indent_count = 1, indent_size = 3)

    asserts.equals(env, expected, actual)

    return unittest.end(env)

serialize_indent_test = unittest.make(_serialize_indent_test)

def _serialize_inline_test(ctx):
    env = unittest.begin(ctx)

    expected = "".join([
        "{",
        '"key": [1, 2, {"a": 1}], ',
        '"flag": True, ',
        '"name": "example", ',
        '"42": None, ',
        '"a": "{foo}"',
        "}",
    ])
    actual = starlark.igen(_DICT)

    asserts.equals(env, expected, actual)

    return unittest.end(env)

serialize_inline_test = unittest.make(_serialize_inline_test)

## --- list ---------------------------------------------

def _serialize_list_empty_test(ctx):
    env = unittest.begin(ctx)

    l = []
    expected = str(l)
    actual = starlark.gen(l)

    asserts.equals(env, expected, actual)

    return unittest.end(env)

serialize_list_empty_test = unittest.make(_serialize_list_empty_test)

def _serialize_list_1_element_test(ctx):
    env = unittest.begin(ctx)

    l = ["a"]
    expected = """
[
    "a",
]
    """.strip()
    actual = starlark.gen(l)

    asserts.equals(env, expected, actual)

    return unittest.end(env)

serialize_list_1_element_test = unittest.make(_serialize_list_1_element_test)

def _serialize_list_2p_elements_test(ctx):
    env = unittest.begin(ctx)

    l = ["a", 1]
    expected = """
[
    "a",
    1,
]
    """.strip()
    actual = starlark.gen(l)

    asserts.equals(env, expected, actual)

    return unittest.end(env)

serialize_list_2p_elements_test = unittest.make(_serialize_list_2p_elements_test)

def _serialize_list_indent_test(ctx):
    env = unittest.begin(ctx)

    l = ["a"]
    expected = """
   [
      "a",
   ]
    """.strip()
    actual = starlark.gen(l, indent_count = 1, indent_size = 3)

    asserts.equals(env, expected, actual)

    return unittest.end(env)

serialize_list_indent_test = unittest.make(_serialize_list_indent_test)

def _serialize_list_quote_test(ctx):
    env = unittest.begin(ctx)

    l = ["a"]
    expected = """
[
    a,
]
    """.strip()
    actual = starlark.gen(l, quote_strings = False)

    asserts.equals(env, expected, actual)

    return unittest.end(env)

serialize_list_quote_test = unittest.make(_serialize_list_quote_test)

## --- dict ---------------------------------------------

def _serialize_dict_empty_test(ctx):
    env = unittest.begin(ctx)

    d = {}
    expected = str(d)
    actual = starlark.gen(d)

    asserts.equals(env, expected, actual)

    return unittest.end(env)

serialize_dict_empty_test = unittest.make(_serialize_dict_empty_test)

def _serialize_dict_1_element_test(ctx):
    env = unittest.begin(ctx)

    d = {"a": "foo"}
    expected = """
{
    "a": "foo",
}
    """.strip()
    actual = starlark.gen(d)

    asserts.equals(env, expected, actual)

    return unittest.end(env)

serialize_dict_1_element_test = unittest.make(_serialize_dict_1_element_test)

def _serialize_dict_2p_elements_test(ctx):
    env = unittest.begin(ctx)

    d = {"a": "foo", 1: "bar"}
    expected = """
{
    "a": "foo",
    1: "bar",
}
    """.strip()
    actual = starlark.gen(d)

    return unittest.end(env)

serialize_dict_2p_elements_test = unittest.make(_serialize_dict_2p_elements_test)

def _serialize_dict_indent_test(ctx):
    env = unittest.begin(ctx)

    d = {"a": "foo"}
    expected = """
   {
      "a": "foo",
   }
    """.strip()
    actual = starlark.gen(d, indent_count = 1, indent_size = 3)

    asserts.equals(env, expected, actual)

    return unittest.end(env)

serialize_dict_indent_test = unittest.make(_serialize_dict_indent_test)

def _serialize_dict_quote_test(ctx):
    env = unittest.begin(ctx)

    d = {"a": "foo"}
    expected = """
{
    a: foo,
}
    """.strip()
    actual = starlark.gen(d, quote_strings = False, quote_keys = False)

    asserts.equals(env, expected, actual)

    return unittest.end(env)

serialize_dict_quote_test = unittest.make(_serialize_dict_quote_test)

def starlark_codegen_tests():
    serialize_list_empty_test(name = _TEST_SUITE_PREFIX + "list/empty")
    serialize_list_1_element_test(name = _TEST_SUITE_PREFIX + "list/1_element")
    serialize_list_2p_elements_test(name = _TEST_SUITE_PREFIX + "list/2+_elements")
    serialize_list_quote_test(name = _TEST_SUITE_PREFIX + "list/quote")
    serialize_list_indent_test(name = _TEST_SUITE_PREFIX + "list/indent")

    serialize_dict_empty_test(name = _TEST_SUITE_PREFIX + "dict/empty")
    serialize_dict_1_element_test(name = _TEST_SUITE_PREFIX + "dict/1_element")
    serialize_dict_2p_elements_test(name = _TEST_SUITE_PREFIX + "dict/2+_elements")
    serialize_dict_quote_test(name = _TEST_SUITE_PREFIX + "dict/quote")
    serialize_dict_indent_test(name = _TEST_SUITE_PREFIX + "dict/indent")

    serialize_indent_test(name = _TEST_SUITE_PREFIX + "serialize/indent")
    serialize_inline_test(name = _TEST_SUITE_PREFIX + "serialize/inline")
