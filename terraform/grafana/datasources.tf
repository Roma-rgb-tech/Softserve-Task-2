resource "grafana_data_source" "prometheus" {
  type       = "prometheus"
  name       = "Prometheus"
  uid        = "prometheus"
  url        = "http://localhost:9090"
  is_default = true

  json_data_encoded = jsonencode({
    timeInterval = "60s"
  })
}

resource "grafana_data_source" "cloudwatch" {
  type = "cloudwatch"
  name = "CloudWatch"
  uid  = "cloudwatch"

  json_data_encoded = jsonencode({
    authType      = "default"
    defaultRegion = var.aws_region
  })

  depends_on = [grafana_data_source.prometheus]
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

  depends_on = [grafana_data_source.prometheus]
}
