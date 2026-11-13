locals {
  hosts_filter = "role=~\"$role\", instance=~\"$instance\""
  hosts_legend = "{{instance}} ({{role}})"

  hosts_expr = {
    status  = "max by (instance, role) (up{${local.hosts_filter}})"
    uptime  = "time() - max by (instance, role) (node_boot_time_seconds{${local.hosts_filter}})"
    cpu     = "100 * (1 - avg by (instance, role) (rate(node_cpu_seconds_total{mode=\"idle\", ${local.hosts_filter}}[5m])))"
    memory  = "100 * (1 - max by (instance, role) (node_memory_MemAvailable_bytes{${local.hosts_filter}}) / max by (instance, role) (node_memory_MemTotal_bytes{${local.hosts_filter}}))"
    disk    = "100 * (1 - max by (instance, role) (node_filesystem_avail_bytes{mountpoint=\"/\", ${local.hosts_filter}}) / max by (instance, role) (node_filesystem_size_bytes{mountpoint=\"/\", ${local.hosts_filter}}))"
    disk_io = "sum by (instance, role) (rate(node_disk_read_bytes_total{${local.hosts_filter}}[5m]) + rate(node_disk_written_bytes_total{${local.hosts_filter}}[5m]))"
    net_in  = "sum by (instance, role) (rate(node_network_receive_bytes_total{device!~\"lo|veth.*|docker.*|br-.*\", ${local.hosts_filter}}[5m]))"
    net_out = "sum by (instance, role) (rate(node_network_transmit_bytes_total{device!~\"lo|veth.*|docker.*|br-.*\", ${local.hosts_filter}}[5m]))"
  }

  hosts_timeseries = [
    { title = "CPU usage", unit = "percent", expr = local.hosts_expr.cpu },
    { title = "Memory usage", unit = "percent", expr = local.hosts_expr.memory },
    { title = "Disk usage (/)", unit = "percent", expr = local.hosts_expr.disk },
    { title = "Disk I/O", unit = "Bps", expr = local.hosts_expr.disk_io },
    { title = "Network in", unit = "Bps", expr = local.hosts_expr.net_in },
    { title = "Network out", unit = "Bps", expr = local.hosts_expr.net_out },
  ]

  hosts_table_columns = ["status", "uptime", "cpu", "memory", "disk"]

  hosts_dashboard = {
    uid           = "hosts"
    title         = "Hosts"
    tags          = ["task2", "infrastructure"]
    timezone      = "browser"
    refresh       = "1m"
    schemaVersion = 39
    time          = { from = "now-3h", to = "now" }

    templating = {
      list = [
        {
          name       = "role"
          label      = "Role"
          type       = "query"
          datasource = local.datasources.prometheus
          definition = "label_values(node_uname_info, role)"
          query      = { query = "label_values(node_uname_info, role)", refId = "role" }
          refresh    = 2
          sort       = 1
          multi      = true
          includeAll = true
          current    = { text = "All", value = "$__all" }
        },
        {
          name       = "instance"
          label      = "Host"
          type       = "query"
          datasource = local.datasources.prometheus
          definition = "label_values(node_uname_info{role=~\"$role\"}, instance)"
          query      = { query = "label_values(node_uname_info{role=~\"$role\"}, instance)", refId = "instance" }
          refresh    = 2
          sort       = 1
          multi      = true
          includeAll = true
          current    = { text = "All", value = "$__all" }
        },
      ]
    }

    panels = concat(
      [
        {
          id         = 1
          type       = "table"
          title      = "Host status"
          datasource = local.datasources.prometheus
          gridPos    = { h = 8, w = 24, x = 0, y = 0 }

          targets = [
            for column in local.hosts_table_columns : {
              refId      = upper(column)
              datasource = local.datasources.prometheus
              expr       = local.hosts_expr[column]
              format     = "table"
              instant    = true
            }
          ]

          transformations = [
            { id = "merge", options = {} },
            {
              id = "organize"
              options = {
                excludeByName = { Time = true }
                indexByName = {
                  role            = 0
                  instance        = 1
                  "Value #STATUS" = 2
                  "Value #UPTIME" = 3
                  "Value #CPU"    = 4
                  "Value #MEMORY" = 5
                  "Value #DISK"   = 6
                }
                renameByName = {
                  role            = "Role"
                  instance        = "Host"
                  "Value #STATUS" = "Status"
                  "Value #UPTIME" = "Uptime"
                  "Value #CPU"    = "CPU"
                  "Value #MEMORY" = "Memory"
                  "Value #DISK"   = "Disk"
                }
              }
            },
          ]

          fieldConfig = {
            defaults = {}
            overrides = [
              {
                matcher = { id = "byName", options = "Status" }
                properties = [
                  { id = "custom.cellOptions", value = { type = "color-background" } },
                  {
                    id = "mappings"
                    value = [{
                      type = "value"
                      options = {
                        "0" = { text = "DOWN", color = "red", index = 0 }
                        "1" = { text = "UP", color = "green", index = 1 }
                      }
                    }]
                  },
                ]
              },
              {
                matcher    = { id = "byName", options = "Uptime" }
                properties = [{ id = "unit", value = "s" }]
              },
              {
                matcher = { id = "byRegexp", options = "CPU|Memory|Disk" }
                properties = [
                  { id = "unit", value = "percent" },
                  { id = "decimals", value = 1 },
                  { id = "custom.cellOptions", value = { type = "color-background", mode = "basic" } },
                  {
                    id = "thresholds"
                    value = {
                      mode = "absolute"
                      steps = [
                        { color = "green", value = null },
                        { color = "orange", value = 80 },
                        { color = "red", value = 90 },
                      ]
                    }
                  },
                ]
              },
            ]
          }
        },
      ],
      [
        for i, panel in local.hosts_timeseries : {
          id         = 10 + i
          type       = "timeseries"
          title      = panel.title
          datasource = local.datasources.prometheus
          gridPos    = { h = 8, w = 12, x = (i % 2) * 12, y = 8 + floor(i / 2) * 8 }

          fieldConfig = {
            defaults  = { unit = panel.unit }
            overrides = []
          }

          options = {
            legend = { displayMode = "list", placement = "bottom", showLegend = true }
          }

          targets = [{
            refId        = "A"
            datasource   = local.datasources.prometheus
            expr         = panel.expr
            legendFormat = local.hosts_legend
          }]
        }
      ],
    )
  }
}

resource "grafana_dashboard" "hosts" {
  folder      = grafana_folder.infrastructure.uid
  config_json = jsonencode(local.hosts_dashboard)
  overwrite   = true
}
