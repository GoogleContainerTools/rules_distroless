<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API re-exports

<a id="cacerts"></a>

## cacerts

<pre>
cacerts(<a href="#cacerts-name">name</a>, <a href="#cacerts-package">package</a>)
</pre>

Create a ca-certificates.crt bundle from Common CA certificates.

When provided with the `ca-certificates` Debian package it will create a bundle
of all common CA certificates at `/usr/share/ca-certificates` and bundle them into
a `ca-certificates.crt` file at `/etc/ssl/certs/ca-certificates.crt`

An example of this would be

```starlark
# MODULE.bazel
http_archive = use_repo_rule("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "ca-certificates",
    type = ".deb",
    canonical_id = "test",
    sha256 = "b2d488ad4d8d8adb3ba319fc9cb2cf9909fc42cb82ad239a26c570a2e749c389",
    urls = ["https://snapshot.debian.org/archive/debian/20231106T210201Z/pool/main/c/ca-certificates/ca-certificates_20210119_all.deb"],
    build_file_content = "exports_files(["data.tar.xz"])"
)

# BUILD.bazel
load("@rules_distroless//distroless:defs.bzl", "cacerts")

cacerts(
    name = "example",
    package = "@ca-certificates//:data.tar.xz",
)
```


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cacerts-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="cacerts-package"></a>package |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


