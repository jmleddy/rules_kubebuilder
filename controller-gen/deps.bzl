""" Dependencies for controller-gen
"""

load("//controller-gen:controller-gen-external.bzl", "controller_gen_external")
load("//controller-gen:controller-gen-repository.bzl", "controller_gen_repository")

def controller_gen_register_toolchain(name = None, version = "0.16.3", sha256s = None):
    """Deprecated: use controller_gen_register_toolchains instead.

    Args:
        name: Retained for compatibility; this argument is ignored.
        version: controller-gen release version to download.
        sha256s: Optional mapping from release platform to SHA-256 checksum.
    """
    controller_gen_register_toolchains(version = version, sha256s = sha256s)

def controller_gen_register_toolchains(version = None, controller_gen_binary = None, sha256s = None):
    if (version == None and controller_gen_binary == None) or (version != None and controller_gen_binary != None):
        fail("Either version or controller_gen_binary must be set")

    repository_name = None

    if version != None:
        repository_name = "controller-gen_%s" % version.replace(".", "_")
        controller_gen_repository(
            name = repository_name,
            version = version,
            sha256s = sha256s or {},
        )
    else:
        if sha256s != None:
            fail("sha256s may only be used with version")
        repository_name = "controller-gen_source"
        controller_gen_external(
            name = repository_name,
            controller_gen_bin = controller_gen_binary,
        )

    native.register_toolchains("@%s//:controller_gen_toolchain_impl" % repository_name)
