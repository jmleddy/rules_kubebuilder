"""Bazel rules for kubebuilder based projects
"""

load(
    "@rules_kubebuilder//kubebuilder:sdk_list.bzl",
    "SDK_VERSION_INTEGRITY",
)

def _kubebuilder_download_sdk_impl(ctx):
    platform = _detect_host_platform(ctx)
    version = ctx.attr.version
    if version not in SDK_VERSION_INTEGRITY:
        fail("Unknown version {}".format(version))
    integrity = SDK_VERSION_INTEGRITY[version][platform]
    urls = [url.format(version = version, platform = platform) for url in ctx.attr.urls]
    strip_prefix = ctx.attr.strip_prefix.format(version = version, platform = platform)
    output = ctx.attr.output.format(version = version, platform = platform)
    ctx.download_and_extract(
        url = urls,
        stripPrefix = strip_prefix,
        integrity = integrity,
        output = output,
    )
    ctx.template(
        "BUILD.bazel",
        Label("@rules_kubebuilder//kubebuilder:BUILD.sdk.bazel"),
        executable = False,
    )

_kubebuilder_download_sdk = repository_rule(
    _kubebuilder_download_sdk_impl,
    attrs = {
        "version": attr.string(default = "1.30.0"),
        "urls": attr.string_list(
            default = [
                "https://github.com/kubernetes-sigs/controller-tools/releases/download/envtest-v{version}/envtest-v{version}-{platform}.tar.gz",
            ],
        ),
        "strip_prefix": attr.string(default = "controller-tools/envtest"),
        "output": attr.string(default = "bin"),
    },
)

def kubebuilder_download_sdk(name, **kwargs):
    _kubebuilder_download_sdk(name = name, **kwargs)

def _detect_host_platform(ctx):
    res = ctx.execute(["uname", "-m"])
    if ctx.os.name == "linux":
        host = "linux-amd64"
    elif ctx.os.name == "mac os x" and res.return_code == 0:
        uname = res.stdout.strip()
        if uname == "amd64":
            host = "darwin-amd64"
        elif uname == "arm64":
            host = "darwin-arm64"
        else:
            fail("Unsupported architecture: " + uname)
    else:
        fail("Unsupported operating system: " + ctx.os.name)
    return host

def kubebuilder_register_sdk(version = "1.30.0"):
    kubebuilder_download_sdk(
        name = "kubebuilder_sdk",
        version = version,
    )

def _kubebuilder_pwd_impl(ctx):
    out_file = ctx.actions.declare_file(ctx.label.name + ".bash")
    exec_path = "$(execpath {})".format(ctx.attr.kubebuilder_binary.label)
    substitutions = {
        "@@PWD@@": ctx.expand_location(exec_path),
    }
    runfiles = None
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = out_file,
        substitutions = substitutions,
        is_executable = True,
    )
    return [DefaultInfo(
        files = depset([out_file]),
        runfiles = runfiles,
        executable = out_file,
    )]

kubebuilder_pwd = rule(
    implementation = _kubebuilder_pwd_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "kubebuilder_binary": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "_template": attr.label(
            default = "@rules_kubebuilder//kubebuilder:kubebuilder_pwd.bash.in",
            allow_single_file = True,
        ),
    },
    executable = True,
)
