"apt extensions"

load("//apt/private:deb_import.bzl", "deb_import")
load("//apt/private:index.bzl", _deb_package_index = "deb_package_index")
load("//apt/private:lockfile.bzl", "lockfile")
load("//apt/private:resolve.bzl", "internal_resolve")

def _distroless_extension(module_ctx):
    root_direct_deps = []
    root_direct_dev_deps = []
    for mod in module_ctx.modules:
        for deb_index in mod.tags.deb_index:
            lockf = None
            if not deb_index.lock:
                lockf = internal_resolve(
                    module_ctx,
                    "yq",
                    deb_index.manifest,
                    deb_index.resolve_transitive,
                )

                # buildifier: disable=print
                print("\nNo lockfile was given, please run `bazel run @%s//:lock` to create the lockfile." % deb_index.name)
            else:
                lockf = lockfile.from_json(module_ctx, module_ctx.read(deb_index.lock))

            for (package) in lockf.packages():
                package_key = lockfile.make_package_key(
                    package["name"],
                    package["version"],
                    package["arch"],
                )

                deb_import(
                    name = "%s_%s" % (deb_index.name, package_key),
                    urls = [package["url"]],
                    sha256 = package["sha256"],
                )

            _deb_package_index(
                name = deb_index.name,
                lock = deb_index.lock,
                manifest = deb_index.manifest,
                lock_content = lockf.as_json(),
            )

            if mod.is_root:
                if module_ctx.is_dev_dependency(deb_index):
                    root_direct_dev_deps.append(deb_index.name)
                else:
                    root_direct_deps.append(deb_index.name)

    return module_ctx.extension_metadata(
        root_module_direct_deps = root_direct_deps,
        root_module_direct_dev_deps = root_direct_dev_deps,
    )

deb_index = tag_class(attrs = {
    "name": attr.string(doc = "Name of the generated repository"),
    "lock": attr.label(doc = """The lock file to use for the index."""),
    "manifest": attr.label(doc = """The file used to generate the lock file"""),
    "resolve_transitive": attr.bool(
        doc = """Whether dependencies of dependencies should be resolved and added to the lockfile.""",
        default = True,
    ),
})

apt = module_extension(
    implementation = _distroless_extension,
    tag_classes = {
        "deb_index": deb_index,
    },
)
