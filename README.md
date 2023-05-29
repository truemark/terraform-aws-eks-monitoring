## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12.26 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.15 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.9.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.10.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.15 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.9.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.10.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_amp_irsa_role"></a> [amp\_irsa\_role](#module\_amp\_irsa\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_prometheus_workspace.k8s](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/prometheus_workspace) | resource |
| [helm_release.prometheus_install](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_amp_arn"></a> [amp\_arn](#input\_amp\_arn) | The AMP workspace arn | `string` | `null` | no |
| <a name="input_amp_id"></a> [amp\_id](#input\_amp\_id) | The AMP workspace id | `string` | `null` | no |
| <a name="input_amp_name"></a> [amp\_name](#input\_amp\_name) | The AMP workspace name | `string` | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster. | `string` | n/a | yes |
| <a name="input_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#input\_cluster\_oidc\_issuer\_url) | The URL on the EKS cluster for the OpenID Connect identity provider | `string` | n/a | yes |
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | The ARN of the OIDC Provider if `enable_irsa = true` | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The AWS region to deploy to. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. | `map(string)` | `{}` | no |

## Outputs

No outputs.
