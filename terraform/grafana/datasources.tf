resource "grafana_data_source" "prometheus" {
  type       = "prometheus"
  name       = "Prometheus"
  uid        = "prometheus"
  url        = "http://localhost:9090"
  is_default = true
}

resource "grafana_data_source" "cloudwatch" {
  type = "cloudwatch"
  name = "CloudWatch"
  uid  = "cloudwatch"

  json_data_encoded = jsonencode({
    authType      = "default"
    defaultRegion = var.aws_region
  })
}

resource "grafana_data_source" "alertmanager" {
  type = "alertmanager"
  name = "Alertmanager"
  uid  = "alertmanager"
  url  = "http://localhost:9093"

  json_data_encoded = jsonencode({
    implementation             = "prometheus"
    handleGrafanaManagedAlerts = true
  })
}
