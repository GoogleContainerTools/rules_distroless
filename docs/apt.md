<!-- Generated with Stardoc: http://skydoc.bazel.build -->

apt-get

<a id="deb_index"></a>

## deb_index

<pre>
deb_index(<a href="#deb_index-name">name</a>, <a href="#deb_index-manifest">manifest</a>, <a href="#deb_index-lock">lock</a>, <a href="#deb_index-package_template">package_template</a>, <a href="#deb_index-resolve_transitive">resolve_transitive</a>)
</pre>

A convience repository macro around package_index and resolve repository rules.

WORKSPACE example;

```starlark
load("@rules_distroless//apt:index.bzl", "deb_index")

deb_index(
    name = "bullseye",
    # For the initial setup, the lockfile attribute can be omitted  and generated by running
    #    bazel run @bullseye//:lock
    # This will generate the lock.json file next to the manifest file by replacing `.yaml` with `.lock.json`
    lock = "//examples/apt:bullseye.lock.json",
    manifest = "//examples/apt:bullseye.yaml",
)

load("@bullseye//:packages.bzl", "bullseye_packages")
bullseye_packages()
```

BZLMOD example;
```starlark
# TODO: support BZLMOD
```

This macro will expand to two repositories;  `&lt;name&gt;` and `&lt;name&gt;_resolve`.

A typical workflow for `deb_index` involves generation of a lockfile `deb_resolve`
and consumption of lockfile by `deb_package_index` for generating a DAG.

The lockfile generation can be `on-demand` by omitting the lock attribute, however,
this comes with the cost of doing a new package resolution on repository cache misses.

While we strongly encourage users to check in the generated lockfile, it's not always
possible to check in the generated lockfile as by default Debian repositories are rolling,
therefore a lockfile generated today might not work work tomorrow  as the upstream
repository might publish new version of a package.

That said, users can still use a `debian archive snapshot` repository and check-in the
generated lockfiles. This is possible because by design `debian snapshot` repositories
are immutable point-in-time snapshot of the upstream repositories, which means packages
never get deleted or updated in a specific snapshot.

An example of this could be found [here](/examples/apt).


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="deb_index-name"></a>name |  name of the repository   |  none |
| <a id="deb_index-manifest"></a>manifest |  label to a <code>manifest.yaml</code>   |  none |
| <a id="deb_index-lock"></a>lock |  label to a <code>lock.json</code>   |  <code>None</code> |
| <a id="deb_index-package_template"></a>package_template |  (EXPERIMENTAL!) a template string for generated BUILD files. Available template replacement keys are: <code>{target_name}</code>, <code>{deps}</code>, <code>{urls}</code>, <code>{name}</code>, <code>{arch}</code>, <code>{sha256}</code>, <code>{repo_name}</code>   |  <code>None</code> |
| <a id="deb_index-resolve_transitive"></a>resolve_transitive |  whether dependencies of dependencies should be resolved and added to the lockfile.   |  <code>True</code> |


