"mocks for unit tests"

def _report_progress():
    return lambda msg: None

def _read(read_output = None):
    return lambda filename: read_output

def _download(success):
    return lambda *args, **kwargs: struct(success = success)

def _execute(results):
    if len(results) < 1:
        fail("You have to provide at least one result to mock execute")

    return lambda *args, **kwargs: results.pop()

def _rctx(**kwargs):
    if "report_progress" not in kwargs:
        kwargs["report_progress"] = _report_progress()

    return struct(**kwargs)

def _pkg(arch, name, version):
    return {
        "Package": name,
        "Architecture": arch,
        "Version": version,
        "Priority": "optional",
        "Section": "foobar",
        "Maintainer": "Mr Foo <mrfoo@debian.org>",
        "Installed-Size": "25",
        "Depends": "libc6 (>= 2.4)",
        "Filename": "bullseye/{}_{}_{}.deb".format(name, version, arch),
        "Size": "19036",
        "MD5sum": "c45cfc046f218bbaf4236fc540280a5f",
        "SHA1": "dc366729ba603e300ed6d13d9b4f28e02227ef3a",
        "SHA256": "f700b85a674ccec8c7214e1ac4e85715dd34f81f215cc6aa78591777972c99cc",
        "SHA512": "1978000b5e45b8f2da94c5b18dbe9ba2e349c78a32b43cc97eda8ac52900b3b2107e8d41eae5b3d7bb191f7b69174d0fa4fcfec8f5e3a364a8bc56caaf06962b",
        "Homepage": "https://mirror.example.com/package=foo",
        "Description": """Foo package
 Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus at neque
 neque. Praesent quis tristique ligula, in fermentum ex. Vivamus tristique sed
 leo eu condimentum. Sed eget massa metus. Mauris facilisis sapien ac leo
 rutrum tincidunt. Donec pretium tincidunt rutrum. Vestibulum convallis lacus
 orci, sit amet eleifend orci ultricies a.
 .
 In sollicitudin porta ex, a malesuada ipsum laoreet nec. Nunc sodales feugiat
 aliquam. Suspendisse scelerisque, neque at egestas vehicula, tellus felis
 consequat sapien, et scelerisque sapien orci vitae sem. Pellentesque magna
 leo, mattis dignissim viverra non, elementum at odio. Aenean diam massa,
 placerat at ex sit amet, ornare laoreet diam.""",
    }

def _packages_index(arch, name, version):
    return "\n".join([
        "{}: {}".format(k, v)
        for k, v in _pkg(arch, name, version).items()
    ]) + "\n"

mock = struct(
    report_progress = _report_progress,
    read = _read,
    download = _download,
    execute = _execute,
    rctx = _rctx,
    pkg = _pkg,
    packages_index = _packages_index,
)
