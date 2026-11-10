package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// +kubebuilder:object:root=true
// +kubebuilder:validation:Optional
type MyCustomResource struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec MyCustomSpec `json:"spec,omitempty"`
}

// +kubebuilder:object:root=true
type MyCustomResources struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []MyCustomResource `json:"items"`
}

type MyCustomSpec struct {
	// +optional
	Descriptions string `json:"descriptions,omitempty"`
}

// +kubebuilder:webhook:path=/mutate-babisk-github-com-v1alpha1-mycustomresource,mutating=true,failurePolicy=fail,sideEffects=None,groups=babisk.github.com,resources=mycustomresource,verbs=create;update,versions=v1alpha1,name=mmycustomresource.kb.io,admissionReviewVersions=v1
// +kubebuilder:rbac:groups=babisk.github.com,resources=mycustomresources,verbs=get;list;watch
