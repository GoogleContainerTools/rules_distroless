"test utilities"

load("@bazel_skylib//lib:sets.bzl", "sets")
load("@bazel_skylib//lib:unittest.bzl", "asserts")

def _asserts_dict_equals(env, edict, adict):
    asserts.set_equals(env, sets.make(edict.keys()), sets.make(adict.keys()))

    for key in edict.keys():
        asserts.equals(env, edict[key], adict[key])

test_util = struct(
    asserts = struct(
        dict_equals = _asserts_dict_equals,
    ),
)
