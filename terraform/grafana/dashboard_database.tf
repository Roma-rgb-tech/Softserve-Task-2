locals {
  database_dimensions = { DBInstanceIdentifier = "*" }
  database_legend     = "{{dimension_DBInstanceIdentifier}}"

  database_stats = [
    {
      title  = "CPU"
      unit   = "percent"
      steps  = [{ color = "green", value = null }, { color = "orange", value = 70 }, { color = "red", value = 80 }]
      target = { refId = "A", datasource = local.datasources.prometheus, instant = true, expr = "max(aws_rds_cpuutilization_average)" }
    },
    {
      title  = "Freeable memory"
      unit   = "bytes"
      steps  = [{ color = "red", value = null }, { color = "orange", value = 26214400 }, { color = "green", value = 104857600 }]
      target = { refId = "A", datasource = local.datasources.prometheus, instant = true, expr = "min(aws_rds_freeable_memory_average)" }
    },
    {
      title  = "Free storage"
      unit   = "bytes"
      steps  = [{ color = "red", value = null }, { color = "orange", value = 2147483648 }, { color = "green", value = 5368709120 }]
      target = { refId = "A", datasource = local.datasources.prometheus, instant = true, expr = "min(aws_rds_free_storage_space_average)" }
    },
    {
      title  = "Connections"
      unit   = "none"
      steps  = [{ color = "blue", value = null }]
      target = merge(local.cloudwatch_query, { refId = "A", namespace = "AWS/RDS", metricName = "DatabaseConnections", statistic = "Average", dimensions = local.database_dimensions })
    },
  ]

  database_timeseries = [
    {
      title   = "CPU utilization"
      unit    = "percent"
      targets = [{ refId = "A", datasource = local.datasources.prometheus, expr = "aws_rds_cpuutilization_average", legendFormat = local.database_legend }]
    },
    {
      title   = "Freeable memory"
      unit    = "bytes"
      targets = [{ refId = "A", datasource = local.datasources.prometheus, expr = "aws_rds_freeable_memory_average", legendFormat = local.database_legend }]
    },
    {
      title   = "Free storage space"
      unit    = "bytes"
      targets = [{ refId = "A", datasource = local.datasources.prometheus, expr = "aws_rds_free_storage_space_average", legendFormat = local.database_legend }]
    },
    {
      title = "Connections"
      unit  = "none"
      targets = [
        merge(local.cloudwatch_query, { refId = "A", namespace = "AWS/RDS", metricName = "DatabaseConnections", statistic = "Average", dimensions = local.database_dimensions }),
      ]
    },
    {
      title = "IOPS"
      unit  = "iops"
      targets = [
        merge(local.cloudwatch_query, { refId = "A", namespace = "AWS/RDS", metricName = "ReadIOPS", statistic = "Average", dimensions = local.database_dimensions, label = "read" }),
        merge(local.cloudwatch_query, { refId = "B", namespace = "AWS/RDS", metricName = "WriteIOPS", statistic = "Average", dimensions = local.database_dimensions, label = "write" }),
      ]
    },
    {
      title = "Latency"
      unit  = "s"
      targets = [
        merge(local.cloudwatch_query, { refId = "A", namespace = "AWS/RDS", metricName = "ReadLatency", statistic = "Average", dimensions = local.database_dimensions, label = "read" }),
        merge(local.cloudwatch_query, { refId = "B", namespace = "AWS/RDS", metricName = "WriteLatency", statistic = "Average", dimensions = local.database_dimensions, label = "write" }),
      ]
    },
  ]

  database_dashboard = {
    uid           = "database"
    title         = "Database"
    tags          = ["task2", "database"]
    timezone      = "browser"
    refresh       = "1m"
    schemaVersion = 39
    time          = { from = "now-6h", to = "now" }
    templating    = { list = [] }

    panels = concat(
      [
        for i, panel in local.database_stats : {
          id         = 1 + i
          type       = "stat"
          title      = panel.title
          datasource = panel.target.datasource
          gridPos    = { h = 4, w = 6, x = i * 6, y = 0 }

          fieldConfig = {
            defaults = {
              unit       = panel.unit
              thresholds = { mode = "absolute", steps = panel.steps }
            }
            overrides = []
          }

          options = {
            colorMode     = "background"
            graphMode     = "area"
            reduceOptions = { calcs = ["lastNotNull"], fields = "", values = false }
          }

          targets = [panel.target]
        }
      ],
      [
        for i, panel in local.database_timeseries : {
          id         = 10 + i
          type       = "timeseries"
          title      = panel.title
          datasource = panel.targets[0].datasource
          gridPos    = { h = 8, w = 12, x = (i % 2) * 12, y = 4 + floor(i / 2) * 8 }

          fieldConfig = {
            defaults  = { unit = panel.unit }
            overrides = []
          }

          options = {
            legend = { displayMode = "list", placement = "bottom", showLegend = true }
          }

          targets = panel.targets
        }
      ],
    )
  }
}

resource "grafana_dashboard" "database" {
  folder      = grafana_folder.database.uid
  config_json = jsonencode(local.database_dashboard)
  overwrite   = true
}
