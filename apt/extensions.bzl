"apt extensions"

load("//apt/private:deb_import.bzl", "deb_import", "make_deb_import_key")
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
                    print(
                        "\nNo lockfile was given. To create one please run " +
                        "`bazel run @{}//:lock`".format(install.name),
                    )
            else:
                lockf = lockfile.from_json(module_ctx, module_ctx.read(install.lock))

            for architectures in lockf.packages.values():
                for package in architectures.values():
                    deb_import_key = make_deb_import_key(install.name, package)

                    deb_import(
                        name = deb_import_key,
                        url = package.url,
                        sha256 = package.sha256,
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
                package_arch_build_template = install.package_arch_build_template,
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
    "package_arch_build_template": attr.label(doc = "(EXPERIMENTAL!) a template file for the generated package BUILD files per architecture."),
})

apt = module_extension(
    implementation = _distroless_extension,
    tag_classes = {
        "install": install,
    },
)
