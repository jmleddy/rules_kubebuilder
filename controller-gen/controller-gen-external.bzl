def _controller_gen_external(ctx):
    controller_gen_bin = ctx.attr.controller_gen_bin

    ctx.file("BUILD.bazel", """
package(default_visibility = ["//visibility:public"])

exports_files(["controller-gen"])

load("@rules_kubebuilder//controller-gen:controller-gen-toolchain.bzl", "controller_gen_toolchain")

controller_gen_toolchain(
    name = "controller_gen_toolchain",
    controller_gen_bin = "{controller_gen_bin}",
)

toolchain(
    name = "controller_gen_toolchain_impl",
    toolchain_type = "@rules_kubebuilder//controller-gen:toolchain",
    toolchain = ":controller_gen_toolchain",
)
""".format(controller_gen_bin = controller_gen_bin))

controller_gen_external = repository_rule(
    implementation = _controller_gen_external,
    attrs = {
        "controller_gen_bin": attr.label(
            allow_files = True,
            mandatory = True,
        ),
    },
    doc = "Generates BUILD.bazel file for controller-gen",
)
