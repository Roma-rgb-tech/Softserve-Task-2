locals {
  services_expr = "max by (instance, name) (node_systemd_unit_state{role=\"$role\", state=\"active\"})"

  services_state_mappings = [{
    type = "value"
    options = {
      "0" = { text = "DOWN", color = "red", index = 0 }
      "1" = { text = "UP", color = "green", index = 1 }
    }
  }]

  services_dashboard = {
    uid           = "services"
    title         = "Services by server type"
    tags          = ["task2", "infrastructure"]
    timezone      = "browser"
    refresh       = "1m"
    schemaVersion = 39
    time          = { from = "now-3h", to = "now" }

    templating = {
      list = [{
        name       = "role"
        label      = "Server type"
        type       = "query"
        datasource = local.datasources.prometheus
        definition = "label_values(node_systemd_unit_state, role)"
        query      = { query = "label_values(node_systemd_unit_state, role)", refId = "role" }
        refresh    = 2
        sort       = 1
        multi      = true
        includeAll = true
        current    = { text = "All", value = "$__all" }
      }]
    }

    panels = [
      {
        id         = 1
        type       = "stat"
        title      = "Services down"
        datasource = local.datasources.prometheus
        gridPos    = { h = 4, w = 12, x = 0, y = 0 }

        fieldConfig = {
          defaults = {
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green", value = null },
                { color = "red", value = 1 },
              ]
            }
          }
          overrides = []
        }

        options = {
          colorMode     = "background"
          graphMode     = "none"
          reduceOptions = { calcs = ["lastNotNull"], fields = "", values = false }
        }

        targets = [{
          refId      = "A"
          datasource = local.datasources.prometheus
          expr       = "count(max by (instance, name) (node_systemd_unit_state{state=\"active\"}) == 0) or vector(0)"
          instant    = true
        }]
      },
      {
        id         = 2
        type       = "stat"
        title      = "Services monitored"
        datasource = local.datasources.prometheus
        gridPos    = { h = 4, w = 12, x = 12, y = 0 }

        fieldConfig = {
          defaults  = {}
          overrides = []
        }

        options = {
          colorMode     = "none"
          graphMode     = "none"
          reduceOptions = { calcs = ["lastNotNull"], fields = "", values = false }
        }

        targets = [{
          refId      = "A"
          datasource = local.datasources.prometheus
          expr       = "count(max by (instance, name) (node_systemd_unit_state{state=\"active\"}))"
          instant    = true
        }]
      },
      {
        id        = 3
        type      = "row"
        title     = "$role"
        repeat    = "role"
        collapsed = false
        gridPos   = { h = 1, w = 24, x = 0, y = 4 }
        panels    = []
      },
      {
        id         = 4
        type       = "stat"
        title      = "Current state"
        datasource = local.datasources.prometheus
        gridPos    = { h = 8, w = 8, x = 0, y = 5 }

        fieldConfig = {
          defaults = {
            mappings = local.services_state_mappings
            color    = { mode = "thresholds" }
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "red", value = null },
                { color = "green", value = 1 },
              ]
            }
          }
          overrides = []
        }

        options = {
          colorMode     = "background"
          graphMode     = "none"
          textMode      = "value_and_name"
          orientation   = "horizontal"
          reduceOptions = { calcs = ["lastNotNull"], fields = "", values = false }
        }

        targets = [{
          refId        = "A"
          datasource   = local.datasources.prometheus
          expr         = local.services_expr
          legendFormat = "{{name}} - {{instance}}"
          instant      = true
        }]
      },
      {
        id         = 5
        type       = "state-timeline"
        title      = "History"
        datasource = local.datasources.prometheus
        gridPos    = { h = 8, w = 16, x = 8, y = 5 }

        fieldConfig = {
          defaults = {
            mappings = local.services_state_mappings
            color    = { mode = "thresholds" }
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "red", value = null },
                { color = "green", value = 1 },
              ]
            }
          }
          overrides = []
        }

        options = {
          showValue   = "never"
          mergeValues = true
          rowHeight   = 0.8
          legend      = { displayMode = "list", placement = "bottom", showLegend = false }
        }

        targets = [{
          refId        = "A"
          datasource   = local.datasources.prometheus
          expr         = local.services_expr
          legendFormat = "{{name}} - {{instance}}"
        }]
      },
    ]
  }
}

resource "grafana_dashboard" "services" {
  folder      = grafana_folder.infrastructure.uid
  config_json = jsonencode(local.services_dashboard)
  overwrite   = true
}
