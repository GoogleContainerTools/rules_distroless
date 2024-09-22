"apt extensions"

load("//apt/private:deb_import.bzl", "deb_import")
load("//apt/private:index.bzl", "deb_package_index")
load("//apt/private:lockfile.bzl", "lockfile")
load("//apt/private:manifest.bzl", "manifest")
load("//apt/private:resolve.bzl", "deb_resolve")

def _distroless_extension(module_ctx):
    root_direct_deps = []
    root_direct_dev_deps = []

    for mod in module_ctx.modules:
        for install in mod.tags.install:
            lockf = None
            if not install.lock:
                lockf = manifest.lock(
                    module_ctx,
                    install.manifest,
                    install.resolve_transitive,
                )

                if not install.nolock:
                    # buildifier: disable=print
                    print("\nNo lockfile was given, please run `bazel run @%s//:lock` to create the lockfile." % install.name)
            else:
                lockf = lockfile.from_json(module_ctx, module_ctx.read(install.lock))

            for (package) in lockf.packages():
                package_key = lockfile.make_package_key(
                    package["name"],
                    package["version"],
                    package["arch"],
                )

                deb_import(
                    name = "%s_%s" % (install.name, package_key),
                    urls = [package["url"]],
                    sha256 = package["sha256"],
                )

            deb_resolve(
                name = install.name + "_resolve",
                manifest = install.manifest,
                resolve_transitive = install.resolve_transitive,
            )

            deb_package_index(
                name = install.name,
                lock = install.lock,
                lock_content = lockf.as_json(),
                package_template = install.package_template,
            )

            if mod.is_root:
                if module_ctx.is_dev_dependency(install):
                    root_direct_dev_deps.append(install.name)
                else:
                    root_direct_deps.append(install.name)

    return module_ctx.extension_metadata(
        root_module_direct_deps = root_direct_deps,
        root_module_direct_dev_deps = root_direct_dev_deps,
    )

install = tag_class(attrs = {
    "name": attr.string(doc = "Name of the generated repository"),
    "lock": attr.label(doc = """The lock file to use for the index."""),
    "nolock": attr.bool(
        doc = """If you explicitly want to run without a lock, set it to True to avoid the DEBUG messages.""",
        default = False,
    ),
    "manifest": attr.label(doc = """The file used to generate the lock file"""),
    "resolve_transitive": attr.bool(
        doc = """Whether dependencies of dependencies should be resolved and added to the lockfile.""",
        default = True,
    ),
    "package_template": attr.label(doc = "(EXPERIMENTAL!) a template file for generated BUILD files."),
})

apt = module_extension(
    implementation = _distroless_extension,
    tag_classes = {
        "install": install,
    },
)
