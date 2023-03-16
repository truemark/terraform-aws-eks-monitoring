data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

data "aws_region" "current" {}

provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

locals {
  oidc_provider            = replace(var.cluster_oidc_issuer_url, "https://", "")
  iamproxy_service_account = "${var.cluster_name}-iamproxy-service-account"
}

module "amp_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${var.cluster_name}-EKSAMPServiceAccountRole"

  attach_amazon_managed_service_prometheus_policy  = true
  amazon_managed_service_prometheus_workspace_arns = [var.amp_arn]

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
    name  = "serviceAccount.server.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.amp_irsa_role.iam_role_arn
    type  = "string"
  }
  set {
    name  = "serviceAccounts.server.name"
    value = local.iamproxy_service_account
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
    value = "https://aps-workspaces.${data.aws_region.current.name}.amazonaws.com/workspaces/${var.amp_id}/api/v1/remote_write"
  }
  set {
    name  = "server.remoteWrite[0].sigv4.region"
    value = data.aws_region.current.name
  }

  timeout = 600
}
