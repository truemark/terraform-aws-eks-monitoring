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

resource "helm_release" "monitoring_stack" {
  repository       = "https://prometheus-community.github.io/helm-charts"
  name             = "prometheus-community"
  namespace        = "monitoring"
  create_namespace = true
  chart            = "kube-prometheus-stack"
  version          = "57.0.3"
  values = [
    <<-EOT
    cleanPrometheusOperatorObjectNames: true
    fullnameOverride: "k8s"
    defaultRules:
      create: ${var.monitoring_stack_create_default_rules}
    alertmanager:
      enabled: ${var.monitoring_stack_enable_alertmanager}
    grafana:
      enabled: ${var.monitoring_stack_enable_grafana}
    prometheus:
      enabled: true
      serviceAccount:
        create: true
        name: "prometheus"
        annotations:
          eks.amazonaws.com/role-arn: ${module.amp_irsa_role.iam_role_arn}
        automountServiceAccountToken: true
      prometheusSpec:
        enableAdminAPI: true
        tolerations: ${jsonencode(var.prometheus_node_tolerations.tolerations)}
        nodeSelector: ${jsonencode(var.prometheus_node_selector.nodeSelector)}
        retention: 1d
        storageSpec:
          volumeClaimTemplate:
            spec:
              storageClassName: gp3
              accessModes: ["ReadWriteOnce"]
              resources:
                requests:
                  storage: ${var.prometheus_pvc_storage_size}
        ruleSelectorNilUsesHelmValues: false
        serviceMonitorSelectorNilUsesHelmValues: false
        podMonitorSelectorNilUsesHelmValues: false
        logLevel: error
        remoteWrite:
        - queue_config:
            capacity: 2500
            max_samples_per_send: 1000
            max_shards: 200
          sigv4:
            region: us-west-2
          url: https://aps-workspaces.${var.region}.amazonaws.com/workspaces/${var.amp_name != null ? aws_prometheus_workspace.k8s.0.id : var.amp_id}/api/v1/remote_write
    EOT
  ]
}

resource "aws_prometheus_workspace" "k8s" {
  count = var.amp_name != null ? 1 : 0

  alias = var.amp_name

  tags = var.tags
}

resource "aws_prometheus_alert_manager_definition" "k8s" {
  count = var.enable_alerts ? 1 : 0

  workspace_id = var.amp_name != null ? aws_prometheus_workspace.k8s.0.id : var.amp_id
  definition   = <<EOF
default_template: |
   {{ define "sns.default.message" }}{{ "{" }}"receiver": "{{ .Receiver }}","source": "prometheus","status": "{{ .Status }}","alerts": [{{ range $alertIndex, $alerts := .Alerts }}{{ if $alertIndex }}, {{ end }}{{ "{" }}"status": "{{ $alerts.Status }}"{{ if gt (len $alerts.Labels.SortedPairs) 0 -}},"labels": {{ "{" }}{{ range $index, $label := $alerts.Labels.SortedPairs }}{{ if $index }}, {{ end }}"{{ $label.Name }}": "{{ $label.Value }}"{{ end }}{{ "}" }}{{- end }}{{ if gt (len $alerts.Annotations.SortedPairs ) 0 -}},"annotations": {{ "{" }}{{ range $index, $annotations := $alerts.Annotations.SortedPairs }}{{ if $index }}, {{ end }}"{{ $annotations.Name }}": "{{ $annotations.Value }}"{{ end }}{{ "}" }}{{- end }},"startsAt": "{{ $alerts.StartsAt }}","endsAt": "{{ $alerts.EndsAt }}","generatorURL": "{{ $alerts.GeneratorURL }}","fingerprint": "{{ $alerts.Fingerprint }}"{{ "}" }}{{ end }}]{{ if gt (len .GroupLabels) 0 -}},"groupLabels": {{ "{" }}{{ range $index, $groupLabels := .GroupLabels.SortedPairs }}{{ if $index }}, {{ end }}"{{ $groupLabels.Name }}": "{{ $groupLabels.Value }}"{{ end }}{{ "}" }}{{- end }}{{ if gt (len .CommonLabels) 0 -}},"commonLabels": {{ "{" }}{{ range $index, $commonLabels := .CommonLabels.SortedPairs }}{{ if $index }}, {{ end }}"{{ $commonLabels.Name }}": "{{ $commonLabels.Value }}"{{ end }}{{ "}" }}{{- end }}{{ if gt (len .CommonAnnotations) 0 -}},"commonAnnotations": {{ "{" }}{{ range $index, $commonAnnotations := .CommonAnnotations.SortedPairs }}{{ if $index }}, {{ end }}"{{ $commonAnnotations.Name }}": "{{ $commonAnnotations.Value }}"{{ end }}{{ "}" }}{{- end }}{{ "}" }}{{ end }}
   {{ define "sns.default.subject" }}[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}]{{ end }}
alertmanager_config: |
  global:
  templates:
    - 'default_template'
  route:
    receiver: 'sns'
  receivers:
    - name: 'sns'
      sns_configs:
        - subject: 'prometheus_alert'
          sigv4:
            region: '${var.region}'
%{if var.alert_role_arn != null}
            role_arn: '${var.alert_role_arn}'
%{endif}
          topic_arn: '${var.alerts_sns_topics_arn}'        
          attributes:
            amp_arn: '${var.amp_name != null ? aws_prometheus_workspace.k8s.0.arn : var.amp_arn}'
            cluster_name: '${var.cluster_name}'
EOF
}

resource "aws_prometheus_rule_group_namespace" "k8s" {
  count = var.enable_alerts ? 1 : 0

  name         = "k8s-rules"
  workspace_id = var.amp_name != null ? aws_prometheus_workspace.k8s.0.id : var.amp_id
  data         = file("${path.module}/rules.yaml")
}
