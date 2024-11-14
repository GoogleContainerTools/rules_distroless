"package resolution"

load(":version.bzl", version_lib = "version")

def _parse_dep(raw):
    raw = raw.strip()  # remove leading & trailing whitespace
    name = None
    version = None
    archs = None

    sqb_start_i = raw.find("[")
    if sqb_start_i != -1:
        sqb_end_i = raw.find("]")
        if sqb_end_i == -1:
            fail('invalid version string %s expected a closing brackets "]"' % raw)
        archs = raw[sqb_start_i + 1:sqb_end_i].strip().split(" ")
        raw = raw[:sqb_start_i] + raw[sqb_end_i + 1:]

    paren_start_i = raw.find("(")
    if paren_start_i != -1:
        paren_end_i = raw.find(")")
        if paren_end_i == -1:
            fail('invalid version string %s expected a closing paren ")"' % raw)
        name = raw[:paren_start_i].strip()
        version_and_const = raw[paren_start_i + 1:paren_end_i].strip()
        raw = raw[:paren_start_i] + raw[paren_end_i + 1:]

        vconst_i = version_and_const.find(" ")
        if vconst_i == -1:
            fail('invalid version string %s expected a version constraint ">=", "=", ">=", "<<", ">>"' % version_and_const)

        version = (version_and_const[:vconst_i], version_and_const[vconst_i + 1:])

    # Depends: python3:any
    # is equivalent to
    # Depends: python3 [any]
    colon_i = raw.find(":")
    if colon_i != -1:
        arch_after_colon = raw[colon_i + 1:]
        raw = raw[:colon_i]
        archs = [arch_after_colon.strip()]

    name = raw.strip()
    return {"name": name, "version": version, "arch": archs}

def _parse_depends(depends_raw):
    depends = []
    for dep in depends_raw.split(","):
        if dep.find("|") != -1:
            depends.append([
                _parse_dep(adep)
                for adep in dep.split("|")
            ])
        else:
            depends.append(_parse_dep(dep))

    return depends

def _version_relop(va, vb, op):
    if op == "<<":
        return version_lib.lt(va, vb)
    elif op == ">>":
        return version_lib.gt(va, vb)
    elif op == "<=":
        return version_lib.lte(va, vb)
    elif op == ">=":
        return version_lib.gte(va, vb)
    elif op == "=":
        return version_lib.eq(va, vb)
    fail("unknown op %s" % op)

def _resolve_package(state, name, version, arch):
    # Get available versions of the package
    versions = state.index.package_versions(name = name, arch = arch)

    # Order packages by highest to lowest
    versions = version_lib.sort(versions, reverse = True)
    package = None
    if version:
        for av in versions:
            if _version_relop(av, version[1], version[0]):
                package = state.index.package(name = name, version = av, arch = arch)

                # Since versions are ordered by hight to low, the first satisfied version will be
                # the highest version and rules_distroless ignores Priority field so it's safe.
                # TODO: rethink this `break` with https://github.com/GoogleContainerTools/rules_distroless/issues/34
                break
    elif len(versions) > 0:
        # First element in the versions list is the latest version.
        version = versions[0]
        package = state.index.package(name = name, version = version, arch = arch)
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
            key = "%s~~%s" % (name, version[1] if version else "")
            unmet_dependencies.append((name, version))
            continue

        # If this package was requested as part of a dependency group, then mark it's group as `dependency met`
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
            deps.extend(_parse_depends(package["Pre-Depends"]))

        # Extend the lookup with all the items in the dependency closure
        if "Depends" in package and include_transitive:
            deps.extend(_parse_depends(package["Depends"]))

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

def _create_resolution(index):
    state = struct(index = index)
    return struct(
        resolve_all = lambda **kwargs: _resolve_all(state, **kwargs),
        resolve_package = lambda **kwargs: _resolve_package(state, **kwargs),
    )

package_resolution = struct(
    new = _create_resolution,
    parse_depends = _parse_depends,
)
