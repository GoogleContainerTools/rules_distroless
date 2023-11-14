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


<a id="locale"></a>

## locale

<pre>
locale(<a href="#locale-name">name</a>, <a href="#locale-charset">charset</a>, <a href="#locale-package">package</a>)
</pre>

Create a locale archive from a Debian package.

An example of this would be

```starlark
# MODULE.bazel
http_archive = use_repo_rule("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "libc-bin",
    build_file_content = 'exports_files(["data.tar.xz"])',
    sha256 = "8b048ab5c7e9f5b7444655541230e689631fd9855c384e8c4a802586d9bbc65a",
    urls = ["https://snapshot.debian.org/archive/debian-security/20231106T230332Z/pool/updates/main/g/glibc/libc-bin_2.31-13+deb11u7_amd64.deb"],
)

# BUILD.bazel
load("@rules_distroless//distroless:defs.bzl", "locale")

locale(
    name = "example",
    package = "@libc-bin//:data.tar.xz"
)
```


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="locale-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="locale-charset"></a>charset |  -   | String | optional | <code>"C.utf8"</code> |
| <a id="locale-package"></a>package |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="os_release"></a>

## os_release

<pre>
os_release(<a href="#os_release-name">name</a>, <a href="#os_release-content">content</a>, <a href="#os_release-path">path</a>, <a href="#os_release-kwargs">kwargs</a>)
</pre>

    Create an Operating System Identification file from a key, value dictionary.

https://www.freedesktop.org/software/systemd/man/latest/os-release.html


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="os_release-name"></a>name |  name of the target   |  none |
| <a id="os_release-content"></a>content |  a key, value dictionary that will be serialized into <code>=</code> seperated lines.<br><br>See https://www.freedesktop.org/software/systemd/man/latest/os-release.html#Options for well known keys.   |  none |
| <a id="os_release-path"></a>path |  where to put the file in the result archive. default: <code>/usr/lib/os-release</code>   |  <code>"/usr/lib/os-release"</code> |
| <a id="os_release-kwargs"></a>kwargs |  other named arguments to expanded targets. see [common rule attributes](https://bazel.build/reference/be/common-definitions#common-attributes).   |  none |


