"package index"

load("@bazel_skylib//lib:paths.bzl", "paths")
load(":version.bzl", version_lib = "version")

def _fetch_package_index(rctx, source):
    # See https://linux.die.net/man/1/xz and https://linux.die.net/man/1/gzip
    #  --keep       -> keep the original file (Bazel might be still committing the output to the cache)
    #  --force      -> overwrite the output if it exists
    #  --decompress -> decompress
    supported_extensions = {
        "xz": ["xz", "--decompress", "--keep", "--force"],
        "gz": ["gzip", "--decompress", "--keep", "--force"],
    }

    failed_attempts = []

    for ext, cmd in supported_extensions.items():
        index_url = source.index_url(ext)
        output_full = source.output_full(ext)

        download = rctx.download(
            url = index_url,
            output = output_full,
            allow_fail = True,
        )

        if not download.success:
            reason = "Download failed. See warning above for details."
            failed_attempts.append((index_url, reason))
            continue

        decompress_cmd = cmd + [output_full]
        decompress_res = rctx.execute(decompress_cmd)

        if decompress_res.return_code == 0:
            break

        reason = "'{cmd}' returned a non-zero exit code: {return_code}"
        reason += "\n\n{stderr}\n{stdout}"
        reason = reason.format(
            cmd = decompress_cmd,
            return_code = decompress_res.return_code,
            stderr = decompress_res.stderr,
            stdout = decompress_res.stdout,
        )

        failed_attempts.append((index_url, reason))

    if len(failed_attempts) == len(supported_extensions):
        attempt_messages = [
            "\n  * '{}' FAILED:\n\n  {}".format(url, reason)
            for url, reason in failed_attempts
        ]

        fail("Failed to fetch packages index:\n" + "\n".join(attempt_messages))

    return rctx.read(source.output)

def _parse_url(url):
    if "://" not in url:
        fail("Invalid URL: %s" % url)

    scheme, url_ = url.split("://", 1)

    path = "/"

    if "/" in url_:
        host, path_ = url_.split("/", 1)
        path += path_
    else:
        host = url_

    return struct(scheme = scheme, host = host, path = path)

def _make_file_url(pkg, source):
    filename = pkg["Filename"]

    invalid_filename = not paths.is_normalized(
        filename,
        look_for_same_level_references = True,
    )

    if invalid_filename:
        # NOTE:
        # Although the Debian repo spec for 'Filename' (see
        # https://wiki.debian.org/DebianRepository/Format#Filename) clearly
        # says that 'Filename' should be relative to the base directory of the
        # repo and should be in canonical form (i.e. without '.' or '..') there
        # are cases where this is not honored.
        #
        # In those cases we try to work around this by assuming 'Filename' is
        # relative to the sources.list "index path" (e.g. directory/ for flat
        # repos) so we combine them and normalize the new 'Filename' path.
        #
        # Note that, so far, only the NVIDIA CUDA repos needed this workaround
        # so maybe this heuristic will break for other repos that don't conform
        # to the Debian repo spec.
        filename = paths.normalize(paths.join(source.index_path, filename))

    base_url = _parse_url(source.base_url)
    file_url = "{}://{}{}".format(
        base_url.scheme,
        base_url.host,
        paths.join(base_url.path, filename),
    )

    return file_url, invalid_filename

def _package_set(packages, keys, package):
    for key in keys[:-1]:
        if key not in packages:
            packages[key] = {}
        packages = packages[key]
    packages[keys[-1]] = package

def _parse_package_index(packages, contents, source):
    last_key = ""
    pkg = {}
    total_pkgs = 0
    out_of_spec = []

    for group in contents.split("\n\n"):
        for line in group.split("\n"):
            if line.strip() == "":
                continue
            if line[0] == " ":
                pkg[last_key] += "\n" + line
                continue

            # This allows for (more) graceful parsing of Package metadata (such as X-* attributes)
            # which may contain patterns that are non-standard. This logic is intended to closely follow
            # the Debian team's parser logic:
            # * https://salsa.debian.org/python-debian-team/python-debian/-/blob/master/src/debian/deb822.py?ref_type=heads#L788
            split = line.split(": ", 1)
            key = split[0]
            value = ""

            if len(split) == 2:
                value = split[1]

            if not last_key and len(pkg) == 0 and key != "Package":
                fail("do not expect this. fix it.")

            last_key = key
            pkg[key] = value

        if len(pkg.keys()) != 0:
            pkg["FileUrl"], invalid_filename = _make_file_url(pkg, source)

            if invalid_filename:
                out_of_spec.append(pkg["Package"])

            # NOTE: workaround for multi-arch flat repos
            arch = source.arch if pkg["Architecture"] == "all" else pkg["Architecture"]

            _package_set(
                packages,
                keys = (arch, pkg["Package"], pkg["Version"]),
                package = pkg,
            )
            last_key = ""
            pkg = {}
            total_pkgs += 1

    return out_of_spec, total_pkgs

def _package_get(packages, arch, name, version = None):
    versions = packages.get(arch, {}).get(name, {})

    if version == None:
        return versions.keys()

    return versions.get(version, None)

def _index(rctx, manifest):
    packages = {}

    for source in manifest.sources:
        index = "%s/%s" % (source.index_path, source.index)

        rctx.report_progress("Fetching package index: %s" % index)
        output = _fetch_package_index(rctx, source)

        rctx.report_progress("Parsing package index: %s" % index)
        out_of_spec, total_pkgs = _parse_package_index(packages, output, source)

        if out_of_spec:
            count = len(out_of_spec)
            pct = int(100.0 * count / total_pkgs)
            msg = "Warning: index {} has {} packages ({}%) with invalid 'Filename' fields"
            print(msg.format(index, count, pct))

    return struct(
        packages = packages,
        package_get = lambda arch, name, version = None: _package_get(packages, arch, name, version),
    )

# "package resolution"

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
        version_and_constraint = raw[paren_start_i + 1:paren_end_i].strip()
        version = version_lib.parse_version_and_constraint(version_and_constraint)
        raw = raw[:paren_start_i] + raw[paren_end_i + 1:]

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

def _resolve_package(index, arch, name, version):
    # Get available versions of the package
    versions = index.package_get(arch, name)

    # Order packages by highest to lowest
    versions = version_lib.sort(versions, reverse = True)
    package = None
    if version:
        for va in versions:
            op, vb = version
            if version_lib.compare(va, op, vb):
                package = index.package_get(arch, name, va)

                # Since versions are ordered by hight to low, the first
                # satisfied version will be the highest version and
                # rules_distroless ignores Priority field so it's safe.
                # TODO: rethink this `break` with issue #34
                break
    elif len(versions) > 0:
        # First element in the versions list is the latest version.
        version = versions[0]
        package = index.package_get(arch, name, version)
    return package

def _resolve_all(index, arch, name, version, include_transitive):
    root_package = None
    already_recursed = {}
    unmet_dependencies = []
    dependencies = []
    has_optional_deps = False
    iteration_max = 2147483646

    stack = [(name, version)]

    for i in range(0, iteration_max + 1):
        if not len(stack):
            break
        if i == iteration_max:
            fail("resolve_dependencies exhausted the iteration")
        (name, version) = stack.pop()

        package = _resolve_package(index, arch, name, version)

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
                # TODO: optional dependencies
                has_optional_deps = True
                continue

            # TODO: arch
            stack.append((dep["name"], dep["version"]))

    if has_optional_deps:
        msg = "Warning: package '{}/{}' (or one of its dependencies) "
        msg += "has optional dependencies that are not supported yet: #27"
        print(msg.format(root_package["Package"], arch))

    if unmet_dependencies:
        msg = "Warning: the following packages have unmet dependencies: {}"
        print(msg.format(",".join([up[0] for up in unmet_dependencies])))

    return root_package, dependencies

def _new(rctx, manifest):
    index = _index(rctx, manifest)

    return struct(
        resolve_all = lambda **kwargs: _resolve_all(index, **kwargs),
        resolve_package = lambda **kwargs: _resolve_package(index, **kwargs),
    )

package_index = struct(
    new = _new,
    parse_depends = _parse_depends,
    # NOTE: these are exposed here for testing purposes, DO NOT USE OTHERWISE
    _fetch_package_index = _fetch_package_index,
    _parse_url = _parse_url,
    _make_file_url = _make_file_url,
    _parse_package_index = _parse_package_index,
    _package_set = _package_set,
    _package_get = _package_get,
    _index = _index,
)
