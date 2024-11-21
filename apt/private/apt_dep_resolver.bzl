"package resolution"

load(":version.bzl", version_lib = "version")
load(":version_constraint.bzl", "version_constraint")

def _resolve_package(repository, arch, name, version):
    if version:
        # First check if the constraint is satisfied by a virtual package
        virtual_packages = repository.virtual_packages(arch, name)

        for provides, package in virtual_packages:
            provided_version = provides["version"]

            if not provided_version:
                continue

            if version_constraint.is_satisfied_by(version, provided_version):
                return package

    # Get available versions of the package
    versions_by_arch = repository.package_versions(arch, name)
    versions_by_any_arch = repository.package_versions("all", name)

    # Order packages by highest to lowest
    versions = version_lib.sort(versions_by_arch + versions_by_any_arch, reverse = True)

    selected_version = None

    if version:
        op, vb = version
        for va in versions:
            if version_lib.compare(va, op, vb):
                selected_version = va

                # Since versions are ordered from high to low and
                # rules_distroless ignores Priority, the first satisfied
                # version will be the highest version.

                # TODO: FR: support package priorities
                # https://github.com/GoogleContainerTools/rules_distroless/issues/34
                break
    elif len(versions) > 0:
        # First element in the versions list is the latest version.
        selected_version = versions[0]

    package = repository.package(arch, name, selected_version)
    if not package:
        package = repository.package("all", name, selected_version)

    return package

_ITERATION_MAX_ = 2147483646

# For future: unfortunately this function uses a few state variables to track
# certain conditions and package dependency groups.
# TODO: Try to simplify it in the future.
def _resolve(repository, arch, name, version, include_transitive):
    root_package_name = name
    root_package = None
    unresolved_dependencies = []
    dependencies = []

    # state variables
    already_recursed = {}
    dependency_group = []
    stack = [(name, version, -1)]

    for i in range(0, _ITERATION_MAX_ + 1):
        if not len(stack):
            break
        if i == _ITERATION_MAX_:
            msg = "Reached _ITERATION_MAX_ trying to resolve %s"
            fail(msg % root_package_name)

        (name, version, dependency_group_idx) = stack.pop()

        # If this iteration is part of a dependency group, and the dependency
        # group is already met, then skip this iteration.
        if dependency_group_idx > -1 and dependency_group[dependency_group_idx]:
            continue

        package = _resolve_package(repository, arch, name, version)

        # If this package is not found and is part of a dependency group, then
        # just skip it.
        if not package and dependency_group_idx > -1:
            continue

        # If this package is not found but is not part of a dependency group,
        # then add it to unresolved_dependencies.
        if not package:
            key = "%s~~%s" % (name, version[1] if version else "")
            unresolved_dependencies.append((name, version))
            continue

        # If this package was requested as part of a dependency group, then
        # mark it's group as resolved.
        if dependency_group_idx > -1:
            dependency_group[dependency_group_idx] = True

        # set the root package, if this is the first iteration
        if i == 0:
            root_package = package

        key = "%s~~%s" % (package["Package"], package["Version"])

        # If we encountered package before in the transitive closure, skip it
        if key in already_recursed:
            continue

        if i != 0:
            # Add it to the dependencies
            already_recursed[key] = True
            dependencies.append(package)

        deps = []

        # Extend the lookup with all the items in the dependency closure
        if "Pre-Depends" in package and include_transitive:
            deps.extend(version_constraint.parse_depends(package["Pre-Depends"]))

        # Extend the lookup with all the items in the dependency closure
        if "Depends" in package and include_transitive:
            deps.extend(version_constraint.parse_depends(package["Depends"]))

        for dep in deps:
            if type(dep) == "list":
                # create a dependency group
                new_dependency_group_idx = len(dependency_group)
                dependency_group.append(False)
                for gdep in dep:
                    # TODO: arch
                    stack.append((gdep["name"], gdep["version"], new_dependency_group_idx))
            else:
                # TODO: arch
                stack.append((dep["name"], dep["version"], -1))

    return root_package, dependencies, unresolved_dependencies

def _new(repository):
    return struct(
        resolve = lambda arch, name, version, include_transitive = True: _resolve(
            repository,
            arch,
            name,
            version,
            include_transitive,
        ),
    )

dependency_resolver = struct(
    new = _new,
)
