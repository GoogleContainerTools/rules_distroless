To replicate the `apt-get install` process with this library, do the following:

* Create a `yaml` file (e.g.: `foo.yaml`) for the library you want to install:
```
version: 1

sources:
  - channel: trusty universe (or other channel as appropriate)
    url: http://archive.ubuntu.com/ubuntu

archs:
  - "amd64"
  - "arm64"

packages:
  - "your-package-here"
```

* In `MODULE.bazel`, load the `apt` extension and install the package:
```
apt = use_extension(
    "@rules_distroless//apt:extensions.bzl",
    "apt",
    dev_dependency = True,
)

apt.install(
    name = "foo",
    lock = "//path/to:foo.lock.json",
    manifest = "//path/to:foo.yaml",
)

use_repo(apt, "foo")
```

* Generate a `lock` file with this command: `bazel run @foo//:lock`

* In the Bazel rule for your `oci_image`, include your package as a tar:
```
oci_image(
    ...
    tars = [
        "@m13n_libs//:m13n_libs",
        ...
    ]
)
```
