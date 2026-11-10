# Keep these checksums for the deprecated no-argument registration default.
# Remove them when controller_gen_register_toolchain is removed.
_DEFAULT_SHA256S = {
    "0.16.3": {
        "darwin-amd64": "7dd0fd1a16b29ba68dee0a1c242f10e87505499059e8e5e00b56cca9bb9f6968",
        "darwin-arm64": "fde18d4dad71a772e187bdc97c2bf712f205618d0f637815442eb501f00fba51",
        "linux-amd64": "8082f45e7aea0251667a5ea39ba58b3d44b536755c15d7e19811786eb40ea38a",
        "linux-arm64": "50b6297e0be9f723e20ac4b648e57a1b3bcc257e4e02d9a942df7aa67e6b5dfa",
        "windows-amd64": "5588ba75651d21da7f5ac5a072ddae8e5f84182ac3eb1189ae1831ee55c97dd8",
    },
}

def _controller_gen_repository_impl(ctx):
    version = ctx.attr.version

    os_map = {
        "linux": "linux",
        "darwin": "darwin",
        "windows": "windows",
    }
    arch_map = {
        "amd64": "amd64",
        "x86_64": "amd64",
        "arm64": "arm64",
        "aarch64": "arm64",
    }

    map_os = {
        "linux": "linux",
        "darwin": "osx",
        "windows": "windows",
    }

    map_arch = {
        "x86_64": "x86_64",
        "amd64": "x86_64",
        "arm64": "arm64",
        "aarch64": "arm64",
    }

    os_name = ctx.os.name
    arch_name = ctx.os.arch
    if os_name in ["mac os x", "macos"]:
        os_name = "darwin"
    elif os_name.startswith("windows"):
        os_name = "windows"
    print("Downloading controller-gen for %s-%s" % (os_name, arch_name))

    if os_name not in os_map:
        fail("Unsupported OS: %s" % os_name)
    if arch_name not in arch_map:
        fail("Unsupported architecture: %s" % arch_name)

    release_os = os_map[os_name]
    release_arch = arch_map[arch_name]
    platform = "%s-%s" % (release_os, release_arch)
    sha256 = ctx.attr.sha256s.get(platform, _DEFAULT_SHA256S.get(version, {}).get(platform, ""))
    if not sha256:
        fail("No SHA-256 checksum configured for controller-gen v%s on %s. " % (version, platform) +
             "Pass sha256s = {\"%s\": \"<sha256>\"} to controller_gen_register_toolchains. " % platform +
             "If the release does not provide a binary for this platform, use controller_gen_binary instead.")

    url = "https://github.com/kubernetes-sigs/controller-tools/releases/download/v{version}/controller-gen-{os}-{arch}{suffix}".format(
        version = version,
        os = release_os,
        arch = release_arch,
        suffix = ".exe" if os_name == "windows" else "",
    )

    controller_gen_bin = ctx.download(
        url = url,
        output = "controller-gen",
        executable = True,
        sha256 = sha256,
        allow_fail = True,
    )
    if not controller_gen_bin.success:
        fail("Could not download controller-gen v%s for %s-%s from %s. " % (version, release_os, release_arch, url) +
             "Check network access, the checksum, and whether the release provides this binary. " +
             "Some older controller-tools releases do not publish binaries; " +
             "use controller_gen_register_toolchains(controller_gen_binary = ...) " +
             "to supply a binary built from source, or choose a release with a matching asset.")

    ctx.file("BUILD.bazel", """
package(default_visibility = ["//visibility:public"])

exports_files(["controller-gen"])

load("@rules_kubebuilder//controller-gen:controller-gen-toolchain.bzl", "controller_gen_toolchain")

controller_gen_toolchain(
    name = "controller_gen_toolchain",
    controller_gen_bin = ":controller-gen",
)

toolchain(
    name = "controller_gen_toolchain_impl",
    toolchain_type = "@rules_kubebuilder//controller-gen:toolchain",
    toolchain = ":controller_gen_toolchain",
    exec_compatible_with = [
        "@platforms//os:{os}",
        "@platforms//cpu:{arch}",
    ],
)
""".format(os = map_os[os_name], arch = map_arch[arch_name]))

controller_gen_repository = repository_rule(
    implementation = _controller_gen_repository_impl,
    attrs = {
        "version": attr.string(mandatory = True),
        "sha256s": attr.string_dict(),
    },
    local = False,
)
