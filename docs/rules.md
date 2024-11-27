<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API re-exports

<a id="cacerts"></a>

## cacerts

<pre>
load("@rules_distroless//distroless:defs.bzl", "cacerts")

cacerts(<a href="#cacerts-name">name</a>, <a href="#cacerts-mode">mode</a>, <a href="#cacerts-package">package</a>, <a href="#cacerts-time">time</a>)
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

To use the generated certificate bundle for SSL, **you must set SSL_CERT_FILE in the
environment**. You can set it on the oci image like so:
```starlark
oci_image(
    name = "my-image",
    env = {
        "SSL_CERT_FILE": "/etc/ssl/certs/ca-certificates.crt",
    }
)
```

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cacerts-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="cacerts-mode"></a>mode |  mode for the entries   | String | optional |  `"0555"`  |
| <a id="cacerts-package"></a>package |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="cacerts-time"></a>time |  time for the entries   | String | optional |  `"0.0"`  |


<a id="flatten"></a>

## flatten

<pre>
load("@rules_distroless//distroless:defs.bzl", "flatten")

flatten(<a href="#flatten-name">name</a>, <a href="#flatten-compress">compress</a>, <a href="#flatten-deduplicate">deduplicate</a>, <a href="#flatten-tars">tars</a>)
</pre>

Flatten multiple archives into single archive.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="flatten-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="flatten-compress"></a>compress |  Compress the archive file with a supported algorithm.   | String | optional |  `""`  |
| <a id="flatten-deduplicate"></a>deduplicate |  EXPERIMENTAL: Remove duplicate entries from the archives after flattening.<br><br>This requires `awk`, `sort` and `tar` to be available in the PATH.<br><br>To support macOS, presence of `gtar` is checked, and `tar` if it does not exist, and ensured if supports the `--delete` mode.<br><br>On macOS: `brew install gnu-tar` can be run to install gnutar. See: https://formulae.brew.sh/formula/gnu-tar<br><br>NOTE: You may also need to run `sudo ln -s /opt/homebrew/bin/gtar /usr/local/bin/gtar` to make it available to Bazel.   | Boolean | optional |  `False`  |
| <a id="flatten-tars"></a>tars |  List of tars to flatten   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |


<a id="java_keystore"></a>

## java_keystore

<pre>
load("@rules_distroless//distroless:defs.bzl", "java_keystore")

java_keystore(<a href="#java_keystore-name">name</a>, <a href="#java_keystore-certificates">certificates</a>, <a href="#java_keystore-mode">mode</a>, <a href="#java_keystore-time">time</a>)
</pre>

Create a java keystore (database) of cryptographic keys, X.509 certificate chains, and trusted certificates.

Currently only public  X.509 are supported as part of the PUBLIC API contract.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="java_keystore-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="java_keystore-certificates"></a>certificates |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="java_keystore-mode"></a>mode |  mode for the entries   | String | optional |  `"0755"`  |
| <a id="java_keystore-time"></a>time |  time for the entries   | String | optional |  `"0.0"`  |


<a id="locale"></a>

## locale

<pre>
load("@rules_distroless//distroless:defs.bzl", "locale")

locale(<a href="#locale-name">name</a>, <a href="#locale-charset">charset</a>, <a href="#locale-package">package</a>, <a href="#locale-time">time</a>)
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
| <a id="locale-charset"></a>charset |  -   | String | optional |  `"C.utf8"`  |
| <a id="locale-package"></a>package |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="locale-time"></a>time |  time for the entries   | String | optional |  `"0.0"`  |


<a id="group"></a>

## group

<pre>
load("@rules_distroless//distroless:defs.bzl", "group")

group(<a href="#group-name">name</a>, <a href="#group-entries">entries</a>, <a href="#group-time">time</a>, <a href="#group-mode">mode</a>, <a href="#group-kwargs">kwargs</a>)
</pre>

Create a group file from array of dicts.

https://www.ibm.com/docs/en/aix/7.2?topic=files-etcgroup-file#group_security__a21597b8__title__1


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="group-name"></a>name |  name of the target   |  none |
| <a id="group-entries"></a>entries |  an array of dicts which will be serialized into single group file.   |  none |
| <a id="group-time"></a>time |  time for the entry   |  `"0.0"` |
| <a id="group-mode"></a>mode |  mode for the entry   |  `"0644"` |
| <a id="group-kwargs"></a>kwargs |  other named arguments to expanded targets. see [common rule attributes](https://bazel.build/reference/be/common-definitions#common-attributes).   |  none |


<a id="home"></a>

## home

<pre>
load("@rules_distroless//distroless:defs.bzl", "home")

home(<a href="#home-name">name</a>, <a href="#home-dirs">dirs</a>, <a href="#home-kwargs">kwargs</a>)
</pre>

Create home directories with specific uid and gids.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="home-name"></a>name |  name of the target   |  none |
| <a id="home-dirs"></a>dirs |  array of home directory dicts.   |  none |
| <a id="home-kwargs"></a>kwargs |  other named arguments to that is passed to tar. see [common rule attributes](https://bazel.build/reference/be/common-definitions#common-attributes).   |  none |


<a id="os_release"></a>

## os_release

<pre>
load("@rules_distroless//distroless:defs.bzl", "os_release")

os_release(<a href="#os_release-name">name</a>, <a href="#os_release-content">content</a>, <a href="#os_release-path">path</a>, <a href="#os_release-mode">mode</a>, <a href="#os_release-time">time</a>, <a href="#os_release-kwargs">kwargs</a>)
</pre>

Create an Operating System Identification file from a key, value dictionary.

https://www.freedesktop.org/software/systemd/man/latest/os-release.html


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="os_release-name"></a>name |  name of the target   |  none |
| <a id="os_release-content"></a>content |  a key, value dictionary that will be serialized into `=` seperated lines.<br><br>See https://www.freedesktop.org/software/systemd/man/latest/os-release.html#Options for well known keys.   |  none |
| <a id="os_release-path"></a>path |  where to put the file in the result archive. default: `/usr/lib/os-release`   |  `"/usr/lib/os-release"` |
| <a id="os_release-mode"></a>mode |  mode for the entry   |  `"0555"` |
| <a id="os_release-time"></a>time |  time for the entry   |  `"0"` |
| <a id="os_release-kwargs"></a>kwargs |  other named arguments to expanded targets. see [common rule attributes](https://bazel.build/reference/be/common-definitions#common-attributes).   |  none |


<a id="passwd"></a>

## passwd

<pre>
load("@rules_distroless//distroless:defs.bzl", "passwd")

passwd(<a href="#passwd-name">name</a>, <a href="#passwd-entries">entries</a>, <a href="#passwd-mode">mode</a>, <a href="#passwd-time">time</a>, <a href="#passwd-kwargs">kwargs</a>)
</pre>

Create a passwd file from array of dicts.

https://www.ibm.com/docs/en/aix/7.3?topic=passwords-using-etcpasswd-file


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="passwd-name"></a>name |  name of the target   |  none |
| <a id="passwd-entries"></a>entries |  an array of dicts which will be serialized into single passwd file.<br><br>An example;<br><br><pre><code>dict(gid = 0, uid = 0, home = "/root", shell = "/bin/bash", username = "root")</code></pre>   |  none |
| <a id="passwd-mode"></a>mode |  mode for the entry   |  `"0644"` |
| <a id="passwd-time"></a>time |  time for the entry   |  `"0.0"` |
| <a id="passwd-kwargs"></a>kwargs |  other named arguments to expanded targets. see [common rule attributes](https://bazel.build/reference/be/common-definitions#common-attributes).   |  none |


