resource "grafana_folder" "llm" {
  title = "LLM"
}

resource "grafana_dashboard" "this" {
  for_each    = fileset("${path.module}/dashboards", "*.json")
  folder      = grafana_folder.llm.uid
  config_json = file("${path.module}/dashboards/${each.value}")
  overwrite   = true
}
