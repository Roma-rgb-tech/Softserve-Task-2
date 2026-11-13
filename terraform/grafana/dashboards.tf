locals {
  community_dashboards = {
    node-exporter-full = {
      id       = 1860
      revision = 46
      folder   = "infrastructure"
    }
    aws-rds = {
      id       = 707
      revision = 8
      folder   = "database"
    }
  }

  folder_uids = {
    infrastructure = grafana_folder.infrastructure.uid
    database       = grafana_folder.database.uid
  }

  datasources = {
    prometheus = { type = "prometheus", uid = grafana_data_source.prometheus.id }
    cloudwatch = { type = "cloudwatch", uid = grafana_data_source.cloudwatch.id }
  }

  cloudwatch_query = {
    datasource       = local.datasources.cloudwatch
    queryMode        = "Metrics"
    metricQueryType  = 0
    metricEditorMode = 0
    region           = "default"
    matchExact       = false
    period           = ""
    id               = ""
    expression       = ""
    label            = ""
  }
}

resource "grafana_folder" "infrastructure" {
  title = "Infrastructure"
}

resource "grafana_folder" "database" {
  title = "Database"
}

resource "grafana_folder" "llm" {
  title = "LLM"
}

data "http" "community_dashboard" {
  for_each = local.community_dashboards
  url      = "https://grafana.com/api/dashboards/${each.value.id}/revisions/${each.value.revision}/download"

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Failed to download Grafana dashboard ${each.value.id} revision ${each.value.revision}"
    }
  }
}

resource "grafana_dashboard" "community" {
  for_each    = local.community_dashboards
  folder      = local.folder_uids[each.value.folder]
  config_json = data.http.community_dashboard[each.key].response_body
  overwrite   = true
}
