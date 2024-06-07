"extensions for bzlmod"

load("//apt/private:index.bzl", _deb_package_index = "deb_package_index", _deb_package_index_bzlmod = "deb_package_index_bzlmod")
load("//apt/private:resolve.bzl", _deb_resolve = "deb_resolve")

deb_index = tag_class(attrs = {
    "name": attr.string(doc = "Name of the generated repository"),
    "lock": attr.label(doc = """The lock file to use for the index."""),
    "manifest": attr.label(doc = """The file used to generate the lock file"""),
    "resolve_transitive": attr.bool(
        doc = """Whether dependencies of dependencies should be resolved and added to the lockfile.""",
        default = True
    ),
})

def _distroless_extension(module_ctx):
    for mod in module_ctx.modules:
        for deb_index in mod.tags.deb_index:
            _deb_package_index_bzlmod(
                module_ctx = module_ctx,
                name = deb_index.name,
                lock = deb_index.lock,
            )

            _deb_resolve(
                name = deb_index.name + "_resolution",
                manifest = deb_index.manifest,
                resolve_transitive = deb_index.resolve_transitive,
            )

            if not deb_index.lock:
                # buildifier: disable=print
                print("\nNo lockfile was given, please run `bazel run @%s//:lock` to create the lockfile." % deb_index.name)

            _deb_package_index(
                name = deb_index.name,
                lock = deb_index.lock if deb_index.lock else "@" + deb_index.name + "_resolution//:lock.json",
                bzlmod = True,
            )

apt = module_extension(
    implementation = _distroless_extension,
    tag_classes = {
        "deb_index": deb_index,
    },
)
