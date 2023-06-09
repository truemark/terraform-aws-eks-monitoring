variable "region" {
  description = "The AWS region to deploy to."
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "amp_name" {
  description = "The AMP workspace name"
  type        = string
  default     = null
}

variable "amp_id" {
  description = "The AMP workspace id"
  type        = string
  default     = null
}

variable "amp_arn" {
  description = "The AMP workspace arn"
  type        = string
  default     = null
}

variable "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if `enable_irsa = true`"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}
