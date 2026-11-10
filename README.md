# rules_kubebuilder

These bazel rules download and make available the [Kubebuilder SDK](https://github.com/kubernetes-sigs/kubebuilder) for building kubernetes operators in bazel.

To use these rules, add the following to your `WORKSPACE` file:

```starlark
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "rules_kubebuilder",
    branch = "main",
    remote = "https://github.com/jmleddy/rules_kubebuilder.git",
)

load("@rules_kubebuilder//kubebuilder:sdk.bzl", "kubebuilder_register_sdk")

kubebuilder_register_sdk(version = "2.3.1")

load("@rules_kubebuilder//controller-gen:deps.bzl", "controller_gen_register_toolchains")

controller_gen_register_toolchains(version = "0.16.3")

load("@rules_kubebuilder//kustomize:deps.bzl", "kustomize_register_toolchain")

kustomize_register_toolchain()
```

And in your `go_test()` files, add `etcd` as a data dependency like this:

```starlark
go_test(
    name = "go_default_test",
    srcs = ["apackage_test.go"],
    data = [
        "@kubebuilder_sdk//:bin/etcd",
    ],
    embed = [":go_default_library"],
    deps = [
    ],
)
```
You'll need to run the test as:

```shell
bazel test --test_env=KUBEBUILDER_ASSETS=$(bazel info execution_root 2>/dev/null)/$(bazel run @kubebuilder_sdk//:pwd 2>/dev/null) //...
```

You can also add the following to `BUILD.bazel` at the root of your workspace:

```starlark
load("@rules_kubebuilder//kubebuilder:def.bzl", "kubebuilder")
kubebuilder(name = "kubebuilder")
```

to be able to run `kubebuilder` like so:

```shell
bazel run //:kubebuilder -- --help
```

## Controller-gen

Register a controller-gen toolchain in `WORKSPACE` using exactly one of a
release version or a label for an existing binary:

```starlark
load("@rules_kubebuilder//controller-gen:deps.bzl", "controller_gen_register_toolchains")

controller_gen_register_toolchains(version = "0.16.3")
# Alternatively, register a binary target:
# controller_gen_register_toolchains(controller_gen_binary = "//tools:controller-gen")
```

The supplied binary must be a publicly visible executable target or executable
file. Executable targets may include runtime data, which is made available when
controller-gen runs.

Version-based registration downloads a binary from the corresponding
controller-tools release, which must provide an asset for the host platform.
Downloads are verified using SHA-256. Checksums for the published v0.16.3
binaries on supported platforms are built in. For other versions, pass a
`sha256s` dictionary mapping each release platform used by your team (for
example, `linux-amd64` or `darwin-arm64`) to its trusted SHA-256 checksum:

```starlark
controller_gen_register_toolchains(
    version = "0.16.3",
    sha256s = {"linux-amd64": "8082f45e7aea0251667a5ea39ba58b3d44b536755c15d7e19811786eb40ea38a"},
)
```

An explicitly supplied checksum takes precedence over a built-in checksum. The
deprecated registration function also accepts `sha256s`. The built-in v0.16.3
checksums support its default and will be removed when that function is removed;
provide your own checksums to prepare for that change.
Some older releases, including v0.12.0 and the previously bundled v0.3.0 and
v0.4.1, do not publish binaries. To use such a version, build controller-gen
from source and register its executable with `controller_gen_binary` instead.
On macOS, both Intel and Apple Silicon hosts are supported when the selected
release provides the corresponding binary. The downloaded toolchain is selected
for the host platform, so remote execution on a different platform is not
supported by this registration method.

The old `controller_gen_register_toolchain` function is deprecated but remains
available. It accepts the existing `name` and `version` arguments; `name` is
ignored, as before. If `version` is omitted, it now defaults to `0.16.3`
(previously `0.3.0`). Explicit versions must have a published binary for the
host platform. Migrate to `controller_gen_register_toolchains` to choose a
version explicitly or use an existing binary.

```starlark
load("@rules_kubebuilder//controller-gen:deps.bzl", "controller_gen_register_toolchain")

controller_gen_register_toolchain()  # Deprecated.
```

CRD, RBAC, and webhook rules accept an optional `out_dir`. If omitted, CRD and
webhook output directories use the rule name, and RBAC uses `rbac`, as in
earlier releases. The CRD rule still accepts the deprecated `trivialVersions`
attribute, but it now defaults to `False`: newer controller-gen versions no
longer support that option. Set it to `True` only when using a compatible older
binary; this passes `trivialVersions=true` to controller-gen.

### Migrating existing controller-gen builds

The deprecated `controller_gen_register_toolchain()` call now selects v0.16.3
instead of v0.3.0. Upgrading controller-gen can change generated manifests and
Go code, so review generated output and update version-specific markers before
adopting the new default. Calls that explicitly requested v0.3.0 or v0.4.1 also
need to migrate: those previously bundled binaries are no longer included, and
their upstream releases do not provide downloadable binaries.

To keep using an older version, provide an executable built from that version
as a public Bazel target and register it in `WORKSPACE`:

```starlark
# In tools/BUILD.bazel, after placing an executable named controller-gen there:
exports_files(["controller-gen"], visibility = ["//visibility:public"])

# In WORKSPACE:
load("@rules_kubebuilder//controller-gen:deps.bzl", "controller_gen_register_toolchains")
controller_gen_register_toolchains(controller_gen_binary = "//tools:controller-gen")
```

For existing CRD rules that depend on the old default `trivialVersions = True`,
set it explicitly when using a compatible older binary. Leave it unset or set it
to `False` for newer versions that do not support the option. The old output
directory defaults remain available when `out_dir` is omitted.

In order to use `controller-gen` you will need to do something like the following in your `api/v1alpha1` directory (essentially where the `*_type.go` files are):

```starlark
load("@io_bazel_rules_go//go:def.bzl", "go_library")
load(
    "@rules_kubebuilder//controller-gen:controller-gen.bzl",
    "controller_gen_crd",
    "controller_gen_object",
    "controller_gen_rbac",
)

filegroup(
    name = "srcs",
    srcs = [
        "groupversion_info.go",
        # your source files here, except for zz_generated_deepcopy.go
    ],
)

DEPS = [
    "@io_k8s_api//core/v1:go_default_library",
    "@io_k8s_apimachinery//pkg/api/resource:go_default_library",
    "@io_k8s_apimachinery//pkg/apis/meta/v1:go_default_library",
    "@io_k8s_apimachinery//pkg/runtime:go_default_library",
    "@io_k8s_apimachinery//pkg/runtime/schema:go_default_library",
    "@io_k8s_sigs_controller_runtime//pkg/scheme:go_default_library",
]

controller_gen_object(
    name = "generated_sources",
    srcs = [
        ":srcs",
    ],
    deps = DEPS,
)

# keep
go_library(
    name = "go_default_library",
    srcs = [
        "generated_sources",
        "srcs",
    ],
    importpath = "yourdomain.com/your-operator/api/v1alpha1",
    visibility = ["//visibility:public"],
    deps = DEPS,
)

controller_gen_crd(
    name = "crds",
    out_dir = "crds",
    srcs = [
        ":srcs",
    ],
    visibility = ["//visibility:public"],
    deps = DEPS,
)
```

## Developers

The integration workspace in `it` tests generated CRDs, RBAC, webhooks, and Go
object code. From that directory, run the test with both the supplied binary
and the downloaded toolchain:

```shell
cd it
bazel test --enable_bzlmod=false //:controller_gen_test
bazel test --enable_bzlmod=false \
  --extra_toolchains=@controller-gen_0_16_3//:controller_gen_toolchain_impl \
  //:controller_gen_test
# On a Linux x86-64 host, check that the supplied generator runs when the
# target platform differs from the execution platform:
bazel test --enable_bzlmod=false --platforms=//:linux_arm64_target //:controller_gen_test
```

These commands use Bazel 7 and the WORKSPACE-based dependency configuration.
