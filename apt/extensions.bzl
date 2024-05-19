"extensions for bzlmod"

load(":index.bzl", _deb_index = "deb_index")
load("//apt/private:index.bzl", _deb_package_index_bzlmod = "deb_package_index_bzlmod")

deb_index = tag_class(attrs = {
    "name": attr.string(doc = "Name of the generated repository"),
    "lock": attr.label(doc = """The lock file to use for the index."""),
    "manifest": attr.label(doc = """The file used to generate the lock file""")
})

def _distroless_extension(module_ctx):
    registrations = {}
    for mod in module_ctx.modules:
        for deb_index in mod.tags.deb_index:
            _deb_package_index_bzlmod(
                module_ctx = module_ctx,
                name = deb_index.name,
                lock = deb_index.lock,
            )
            
            _deb_index(
                name = deb_index.name,
                lock = deb_index.lock,
                manifest = deb_index.manifest,
                bzlmod = True
            )

apt = module_extension(
    implementation = _distroless_extension,
    tag_classes = {
        "deb_index": deb_index
    },
)