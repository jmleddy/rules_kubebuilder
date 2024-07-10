# rules_kubebuilder

These bazel rules download and make available the [Kubebuilder SDK](https://github.com/kubernetes-sigs/kubebuilder) for building kubernetes operators in bazel.

To use these rules, add the following to your `WORKSPACE` file:

```starlark
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "rules_kubebuilder",
    branch = "main",
    remote = "https://github.com/ob/rules_kubebuilder.git",
)

load("@rules_kubebuilder//kubebuilder:sdk.bzl", "kubebuilder_register_sdk")

kubebuilder_register_sdk(version = "1.30.0")
load("@rules_kubebuilder//controller-gen:deps.bzl", "controller_gen_register_toolchain")

controller_gen_register_toolchain()

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
        "@kubebuilder_sdk//:bin/kube-apiserver",
    ],
    env = {
        "KUBEBUILDER_ASSETS": "../../kubebuilder_sdk/bin",
    },
    embed = [":go_default_library"],
    deps = [
    ],
)
```

You can run the test with:

```shell
bazel test //...
```

Unfortunately due to an
[issue](https://github.com/bazelbuild/bazel/issues/15985) with the way
bazel refers to relative paths, you must tailor the
KUBEBUILDER_ASSETS to the particular directory structure of the test
target. Since in this directory `apackage_test.go` is in the `//test`
subdir, we must go up one level, and then another level to get to the
runfiles location where we expect the kubebuilder_sdk data
directory. If you'd prefer not to have to do this, you can run he old
way with:

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
    srcs = [
        ":srcs",
    ],
    visibility = ["//visibility:public"],
    deps = DEPS,
)
```

## Developers

The toolchain that describes `controller-gen` needs to be built and the binaries committed so that
they can be used. Fortunately Go supports cross compiling so in order to build the controller, you'll
need to get and install Go either from [their download page](https://golang.org/doc/install) or from
homebrew by running

```shell
brew install golang
```

After that you can run the script in `scripts/build-controller-gen.sh` which will compile `controller-gen`
for both Linux and macOS.
