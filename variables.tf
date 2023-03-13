variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "amp_id" {
  description = "The AMP workspace id"
  type        = string
}

variable "amp_arn" {
  description = "The AMP workspace arn"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  type        = string
}
