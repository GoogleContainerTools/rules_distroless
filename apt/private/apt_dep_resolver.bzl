"package resolution"

load(":version.bzl", version_lib = "version")
load(":version_constraint.bzl", "version_constraint")

def _resolve_package(state, name, version, arch):
    # First check if the constraint is satisfied by a virtual package
    virtual_packages = state.repository.virtual_packages(name = name, arch = arch)
    for (provides, package) in virtual_packages:
        provided_version = provides["version"]
        if not provided_version and version:
            continue
        if provided_version and version:
            if version_constraint.is_satisfied_by(version, provided_version):
                return package

    # Get available versions of the package
    versions_by_arch = state.repository.package_versions(name = name, arch = arch)
    versions_by_any_arch = state.repository.package_versions(name = name, arch = "all")

    # Order packages by highest to lowest
    versions = version_lib.sort(versions_by_arch + versions_by_any_arch, reverse = True)

    selected_version = None

    if version:
        for av in versions:
            if version_constraint.relop(av, version[1], version[0]):
                selected_version = av

                # Since versions are ordered by hight to low, the first satisfied version will be
                # the highest version and rules_distroless ignores Priority field so it's safe.
                # TODO: rethink this `break` with https://github.com/GoogleContainerTools/rules_distroless/issues/34
                break
    elif len(versions) > 0:
        # First element in the versions list is the latest version.
        selected_version = versions[0]

    package = state.repository.package(name = name, version = selected_version, arch = arch)
    if not package:
        package = state.repository.package(name = name, version = selected_version, arch = "all")

    return package

_ITERATION_MAX_ = 2147483646

# For future: unfortunately this function uses a few state variables to track
# certain conditions and package dependency groups.
# TODO: Try to simplify it in the future.
def _resolve_all(state, name, version, arch, include_transitive = True):
    root_package = None
    unmet_dependencies = []
    dependencies = []

    # state variables
    already_recursed = {}
    dependency_group = []
    stack = [(name, version, -1)]

    for i in range(0, _ITERATION_MAX_ + 1):
        if not len(stack):
            break
        if i == _ITERATION_MAX_:
            fail("resolve_all exhausted")

        (name, version, dependency_group_idx) = stack.pop()

        # If this iteration is part of a dependency group, and the dependency group is already met, then skip this iteration.
        if dependency_group_idx > -1 and dependency_group[dependency_group_idx]:
            continue

        package = _resolve_package(state, name, version, arch)

        # If this package is not found and is part of a dependency group, then just skip it.
        if not package and dependency_group_idx > -1:
            continue

        # If this package is not found but is not part of a dependency group, then add it to unmet dependencies.
        if not package:
            unmet_dependencies.append((name, version))
            continue

        # If this package was requested as part of a dependency group, then mark it's group as `dependency met`
        if dependency_group_idx > -1:
            dependency_group[dependency_group_idx] = True

        # set the root package, if this is the first iteration
        if i == 0:
            root_package = package

        key = package["Package"]

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

    return (root_package, dependencies, unmet_dependencies)

def _create_resolution(repository):
    state = struct(repository = repository)
    return struct(
        resolve_all = lambda **kwargs: _resolve_all(state, **kwargs),
        resolve_package = lambda **kwargs: _resolve_package(state, **kwargs),
    )

dependency_resolver = struct(
    new = _create_resolution,
)
