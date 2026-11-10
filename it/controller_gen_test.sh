#!/usr/bin/env bash
set -euo pipefail

root="${TEST_SRCDIR}/${TEST_WORKSPACE}"
crd="${root}/$1/babisk.github.com_mycustomresources.yaml"
rbac="${root}/$2/role.yaml"
webhook="${root}/$3/manifests.yaml"
objects="${root}/$4"

grep -Fq 'kind: CustomResourceDefinition' "$crd"
grep -Fq 'name: mycustomresources.babisk.github.com' "$crd"
grep -Fq 'kind: ClusterRole' "$rbac"
grep -Fq 'mycustomresources' "$rbac"
grep -Fq 'kind: MutatingWebhookConfiguration' "$webhook"
grep -Fq 'mmycustomresource.kb.io' "$webhook"
grep -Fq 'func (in *MyCustomResource) DeepCopyObject()' "$objects"

[[ "${5##*/}" == "legacy_crds" && "${6##*/}" == "rbac" && "${7##*/}" == "legacy_webhook" ]]
grep -Fq 'kind: CustomResourceDefinition' "${root}/$5/babisk.github.com_mycustomresources.yaml"
grep -Fq 'kind: ClusterRole' "${root}/$6/role.yaml"
grep -Fq 'kind: MutatingWebhookConfiguration' "${root}/$7/manifests.yaml"
grep -Fq 'kind: CustomResourceDefinition' "${root}/$8/babisk.github.com_mycustomresources.yaml"
