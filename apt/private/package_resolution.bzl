"package resolution"

load(":version.bzl", "version")

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
        return version.lt(va, vb)
    elif op == ">>":
        return version.gt(va, vb)
    elif op == "<=":
        return version.lte(va, vb)
    elif op == ">=":
        return version.gte(va, vb)
    elif op == "=":
        return version.eq(va, vb)
    fail("unknown op %s" % op)

def _resolve_package(state, name, version, arch):
    versions = state.index.package_versions(name = name, arch = arch)
    package = None
    if version:
        for av in versions:
            if _version_relop(av, version[1], version[0]):
                package = state.index.package(name = name, version = av, arch = arch)
                break
    elif len(versions) > 0:
        # TODO: what do we do when there is no version constraint?
        package = state.index.package(name = name, version = versions[0], arch = arch)
    return package

def _resolve_all(state, name, version, arch, in_lock, include_transitive):
    root_package = None
    already_recursed = {}
    unmet_dependencies = []
    dependencies = []
    iteration_max = 2147483646

    stack = [(name, version)]

    for i in range(0, iteration_max + 1):
        if not len(stack):
            break
        if i == iteration_max:
            fail("resolve_dependencies exhausted the iteration")
        (name, version) = stack.pop()

        package = _resolve_package(state, name, version, arch)

        if not package:
            key = "%s~~%s" % (name, version[1] if version else "")
            unmet_dependencies.append((name, version))
            continue

        if i == 0:
            # Set the root package
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
                # buildifier: disable=print
                print("Warning: optional dependencies are not supported yet. https://github.com/GoogleContainerTools/rules_distroless/issues/27")

                # TODO: optional dependencies
                continue

            # TODO: arch
            stack.append((dep["name"], dep["version"]))

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
