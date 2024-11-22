"mocks for unit tests"

_URL = "http://nowhere"
_ARCH = "amd64"
_VERSION = "0.3.20-1~bullseye.1"

_SOURCE = {
    "arch": _ARCH,
    "url": _URL,
    "dist": "bullseye",
    "comp": "main",
}

_CHANNEL = "%s %s" % (_SOURCE["dist"], _SOURCE["comp"])

_MANIFEST_LABEL = "mock_manifest"

_PKG_DEPS_V1 = [
    {
        "key": "tar_1.34-p-dfsg-1-p-deb11u1_arm64",
        "name": "tar",
        "version": "1.34+dfsg-1+deb11u1",
    },
    {
        "key": "libselinux1_3.1-3_arm64",
        "name": "libselinux1",
        "version": "3.1-3",
    },
    {
        "key": "libbz2-1.0_1.0.8-4_arm64",
        "name": "libbz2-1.0",
        "version": "1.0.8-4",
    },
]

_PKG_LOCK_V1 = {
    "arch": _ARCH,
    "dependencies": _PKG_DEPS_V1,
    "key": "dpkg_1.20.13_arm64",
    "name": "dpkg",
    "sha256": "87b0bce7361d94cc15caf27709fa8a70de44f9dd742cf0d69d25796a03d24853",
    "url": "%s/dpkg_1.20.13_arm64.deb" % _URL,
    "version": "1.20.13",
}

_PKG_DEPS_V2 = [
    {
        "name": "libbz2-1.0",
        "version": "1.0.8-4",
    },
    {
        "name": "libselinux1",
        "version": "3.1-3",
    },
    {
        "name": "tar",
        "version": "1.34+dfsg-1+deb11u1",
    },
]

_PKG_LOCK_V2 = {
    "arch": _ARCH,
    "dependencies": _PKG_DEPS_V2,
    "name": "dpkg",
    "sha256": "eb2b7ba3a3c4e905a380045a2d1cd219d2d45755aba5966d6c804b79400beb05",
    "url": "%s/dpkg_1.20.13_amd64.deb" % _URL,
    "version": "1.20.13",
}

_PKG_INDEX = {
    "Package": _PKG_LOCK_V2["name"],
    "Architecture": _PKG_LOCK_V2["arch"],
    "Version": _PKG_LOCK_V2["version"],
    "File-Url": _PKG_LOCK_V2["url"],
    "Filename": _PKG_LOCK_V2["url"].split("/")[-1],
    "SHA256": _PKG_LOCK_V2["sha256"],
}

_PKG_INDEX_DEPS = [
    {
        "Package": d["name"],
        "Version": d["version"],
        "File-Url": "http://nowhere/foo.deb",
        "Filename": "foo.deb",
        "SHA256": "deadbeef" * 8,
    }
    for d in _PKG_DEPS_V2
]

_LOCK_V1 = {
    "packages": [
        {
            "arch": _ARCH,
            "dependencies": [],
            "key": "ncurses-base_6.2-p-20201114-2-p-deb11u2_amd64",
            "name": "ncurses-base",
            "sha256": "a55a5f94299448279da6a6c2031a9816dc768cd300668ff82ecfc6480bbfc83d",
            "url": "%s/ncurses-base_6.2+20201114-2+deb11u2_all.deb" % _URL,
            "version": "6.2+20201114-2+deb11u2",
        },
        {
            "arch": _ARCH,
            "dependencies": [
                {
                    "key": "tar_1.34-p-dfsg-1-p-deb11u1_arm64",
                    "name": "tar",
                    "version": "1.34+dfsg-1+deb11u1",
                },
                {
                    "key": "libselinux1_3.1-3_arm64",
                    "name": "libselinux1",
                    "version": "3.1-3",
                },
                {
                    "key": "libbz2-1.0_1.0.8-4_arm64",
                    "name": "libbz2-1.0",
                    "version": "1.0.8-4",
                },
            ],
            "key": "dpkg_1.20.13_arm64",
            "name": "dpkg",
            "sha256": "87b0bce7361d94cc15caf27709fa8a70de44f9dd742cf0d69d25796a03d24853",
            "url": "%s/dpkg_1.20.13_arm64.deb" % _URL,
            "version": "1.20.13",
        },
    ],
    "version": 1,
}

_LOCK_V2 = {
    "packages": {
        "dpkg": {
            _ARCH: _PKG_LOCK_V2,
        },
        "ncurses-base": {
            _ARCH: {
                "arch": _ARCH,
                "dependencies": [],
                "key": "ncurses-base_6.2-p-20201114-2-p-deb11u2_amd64",
                "name": "ncurses-base",
                "sha256": "a55a5f94299448279da6a6c2031a9816dc768cd300668ff82ecfc6480bbfc83d",
                "url": "%s/ncurses-base_6.2+20201114-2+deb11u2_all.deb" % _URL,
                "version": "6.2+20201114-2+deb11u2",
            },
        },
    },
    "version": 2,
}

mock_value = struct(
    URL = _URL,
    ARCH = _ARCH,
    SOURCE = _SOURCE,
    CHANNEL = _CHANNEL,
    MANIFEST_LABEL = _MANIFEST_LABEL,
    PKG_DEPS_V1 = _PKG_DEPS_V1,
    PKG_LOCK_V1 = _PKG_LOCK_V1,
    PKG_DEPS_V2 = _PKG_DEPS_V2,
    PKG_LOCK_V2 = _PKG_LOCK_V2,
    PKG_INDEX = _PKG_INDEX,
    PKG_INDEX_DEPS = _PKG_INDEX_DEPS,
    LOCK_V1 = _LOCK_V1,
    LOCK_V2 = _LOCK_V2,
)

def _execute(arguments = None, **kwargs):
    return lambda *args, **kwargs: arguments.pop() if arguments else None

def _report_progress():
    return lambda msg: None

def _read(read_output = None):
    return lambda filename: read_output

def _download(success):
    return lambda *args, **kwargs: struct(success = success)

def _rctx(**kwargs):
    if "execute" not in kwargs:
        kwargs["execute"] = _execute([])

    if "report_progress" not in kwargs:
        kwargs["report_progress"] = _report_progress()

    return struct(**kwargs)

def _pkg(package, **kwargs):
    defaults = {
        "Package": package,
        "Filename": "/foo/bar/pkg.deb",
        "SHA256": "deadbeef" * 8,
    }

    pkg = {k.title().replace("_", "-"): v for k, v in kwargs.items()}

    return defaults | pkg

def _pkg_index(pkg):
    return "\n".join([
        "{}: {}".format(k, v)
        for k, v in pkg.items()
    ]) + "\n\n"

def _packages_index_content(*pkgs):
    return "".join([_pkg_index(pkg) for pkg in pkgs])

def _manifest_dict(**kwargs):
    defaults = {
        "version": 1,
        "url": _URL,
        "archs": [_ARCH],
        "sources": [{"channel": _CHANNEL, "url": _URL}],
        "packages": [],
    }

    return defaults | kwargs

mock = struct(
    execute = _execute,
    rctx = _rctx,
    report_progress = _report_progress,
    read = _read,
    download = _download,
    pkg = _pkg,
    pkg_index = _pkg_index,
    packages_index_content = _packages_index_content,
    manifest_dict = _manifest_dict,
)
