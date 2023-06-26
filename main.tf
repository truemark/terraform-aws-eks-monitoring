locals {
  oidc_provider            = replace(var.cluster_oidc_issuer_url, "https://", "")
  iamproxy_service_account = "amp-iamproxy-service-account"
}

module "amp_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${var.cluster_name}-EKSAMPServiceAccountRole"

  attach_amazon_managed_service_prometheus_policy  = true
  amazon_managed_service_prometheus_workspace_arns = [var.amp_name != null ? aws_prometheus_workspace.k8s.0.arn : var.amp_arn]

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["prometheus:${local.iamproxy_service_account}"]
    }
  }

  tags = var.tags
}

resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "prometheus"
  }
}

resource "helm_release" "prometheus_install" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = kubernetes_namespace.prometheus.metadata[0].name

  set {
    name  = "serviceAccounts.server.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.amp_irsa_role.iam_role_arn
    type  = "string"
  }
  set {
    name  = "serviceAccounts.server.name"
    value = local.iamproxy_service_account
    type  = "string"
  }
  set {
    name  = "alertmanager.enabled"
    value = false
  }
  set {
    name  = "prometheus-pushgateway.enabled"
    value = false
  }
  set {
    name  = "server.remoteWrite[0].url"
    value = "https://aps-workspaces.${var.region}.amazonaws.com/workspaces/${var.amp_name != null ? aws_prometheus_workspace.k8s.0.id : var.amp_id}/api/v1/remote_write"
    type  = "string"
  }
  set {
    name  = "server.remoteWrite[0].sigv4.region"
    value = var.region
    type  = "string"
  }
  set {
    name  = "server.remoteWrite[0].queue_config.max_samples_per_send"
    value = 1000
  }
  set {
    name  = "server.remoteWrite[0].queue_config.max_shards"
    value = 200
  }
  set {
    name  = "server.remoteWrite[0].queue_config.capacity"
    value = 2500
  }

  timeout = 600
}

resource "aws_prometheus_workspace" "k8s" {
  count = var.amp_name != null ? 1 : 0

  alias = var.amp_name

  tags = var.tags
}

resource "aws_prometheus_rule_group_namespace" "k8s" {
  name         = "k8s-rules"
  workspace_id = var.amp_name != null ? aws_prometheus_workspace.k8s.0.id : var.amp_id
  data         = file("${path.module}/rules.yaml")
}
