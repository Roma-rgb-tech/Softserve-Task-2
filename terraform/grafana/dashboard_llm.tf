locals {
  llm_alb_search    = "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"%s\" \"llm-alb\"', '%s', 60)"
  llm_target_search = "SEARCH('{AWS/ApplicationELB,TargetGroup} MetricName=\"RequestCountPerTarget\" \"llm-tg\"', 'Sum', 60)"

  llm_owui_requests = "{__name__=~\"http_server_requests(_total)?\", role=\"open-webui\"}"
  llm_owui_duration = "{__name__=~\"http_server_duration(_milliseconds)?_bucket\", role=\"open-webui\"}"
  llm_chat_route    = "http_route=~\".*/chat/completions\""
  llm_generations   = "ollama_requests_total{role=\"ollama\", path=~\"/api/(chat|generate)\"}"

  llm_stats = [
    {
      title  = "Ollama hosts active"
      unit   = "none"
      calc   = "lastNotNull"
      steps  = [{ color = "red", value = null }, { color = "orange", value = 1 }, { color = "green", value = 2 }]
      target = { refId = "A", datasource = local.datasources.prometheus, instant = true, expr = "count(node_systemd_unit_state{name=\"ollama.service\", state=\"active\"} == 1) or vector(0)" }
    },
    {
      title  = "LLM healthy hosts"
      unit   = "none"
      calc   = "lastNotNull"
      steps  = [{ color = "red", value = null }, { color = "orange", value = 1 }, { color = "green", value = 2 }]
      target = { refId = "A", datasource = local.datasources.prometheus, instant = true, expr = "min(aws_applicationelb_healthy_host_count_minimum{dimension_TargetGroup=~\"targetgroup/.*-llm-tg/.*\"})" }
    },
    {
      title  = "LLM requests (ALB)"
      unit   = "none"
      calc   = "sum"
      steps  = [{ color = "blue", value = null }]
      target = merge(local.cloudwatch_query, { refId = "A", metricEditorMode = 1, expression = format(local.llm_alb_search, "RequestCount", "Sum"), label = "requests" })
    },
    {
      title  = "LLM p95 response time"
      unit   = "s"
      calc   = "mean"
      steps  = [{ color = "green", value = null }, { color = "orange", value = 30 }, { color = "red", value = 120 }]
      target = merge(local.cloudwatch_query, { refId = "A", metricEditorMode = 1, expression = format(local.llm_alb_search, "TargetResponseTime", "p95"), label = "p95" })
    },
    {
      title  = "Open WebUI users"
      unit   = "none"
      calc   = "lastNotNull"
      steps  = [{ color = "blue", value = null }]
      target = { refId = "A", datasource = local.datasources.prometheus, instant = true, expr = "max({__name__=~\"webui_users_total(_users)?\", role=\"open-webui\"})" }
    },
    {
      title  = "Open WebUI active users"
      unit   = "none"
      calc   = "lastNotNull"
      steps  = [{ color = "blue", value = null }]
      target = { refId = "A", datasource = local.datasources.prometheus, instant = true, expr = "max({__name__=~\"webui_users_active(_users)?\", role=\"open-webui\"})" }
    },
  ]

  llm_timeseries = [
    {
      title = "Ollama hosts CPU"
      unit  = "percent"
      targets = [{
        refId        = "A"
        datasource   = local.datasources.prometheus
        expr         = "100 * (1 - avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\", role=\"ollama\"}[5m])))"
        legendFormat = "{{instance}}"
      }]
    },
    {
      title = "Ollama hosts memory"
      unit  = "percent"
      targets = [{
        refId        = "A"
        datasource   = local.datasources.prometheus
        expr         = "100 * (1 - node_memory_MemAvailable_bytes{role=\"ollama\"} / node_memory_MemTotal_bytes{role=\"ollama\"})"
        legendFormat = "{{instance}}"
      }]
    },
    {
      title = "LLM requests per minute (ALB)"
      unit  = "none"
      targets = [
        merge(local.cloudwatch_query, { refId = "A", metricEditorMode = 1, expression = format(local.llm_alb_search, "RequestCount", "Sum"), label = "all requests" }),
      ]
    },
    {
      title = "LLM response time (ALB)"
      unit  = "s"
      targets = [
        merge(local.cloudwatch_query, { refId = "A", metricEditorMode = 1, expression = format(local.llm_alb_search, "TargetResponseTime", "Average"), label = "average" }),
        merge(local.cloudwatch_query, { refId = "B", metricEditorMode = 1, expression = format(local.llm_alb_search, "TargetResponseTime", "p95"), label = "p95" }),
      ]
    },
    {
      title = "Requests per instance per minute (scaling metric, target 5)"
      unit  = "none"
      targets = [
        merge(local.cloudwatch_query, { refId = "A", metricEditorMode = 1, expression = local.llm_target_search, label = "RequestCountPerTarget" }),
      ]
    },
    {
      title = "Ollama generations per minute per instance"
      unit  = "none"
      targets = [{
        refId        = "A"
        datasource   = local.datasources.prometheus
        expr         = "sum by (instance) (rate(${local.llm_generations}[5m])) * 60"
        legendFormat = "{{instance}}"
      }]
    },
    {
      title = "ALB target errors"
      unit  = "none"
      targets = [
        { refId = "A", datasource = local.datasources.prometheus, expr = "sum(aws_applicationelb_httpcode_target_4_xx_count_sum)", legendFormat = "4XX" },
        { refId = "B", datasource = local.datasources.prometheus, expr = "sum(aws_applicationelb_httpcode_target_5_xx_count_sum)", legendFormat = "5XX" },
      ]
    },
    {
      title = "ALB healthy hosts"
      unit  = "none"
      targets = [{
        refId        = "A"
        datasource   = local.datasources.prometheus
        expr         = "min by (dimension_TargetGroup) (aws_applicationelb_healthy_host_count_minimum)"
        legendFormat = "{{dimension_TargetGroup}}"
      }]
    },
    {
      title = "Chat requests (Open WebUI)"
      unit  = "none"
      targets = [{
        refId        = "A"
        datasource   = local.datasources.prometheus
        expr         = "sum(increase({__name__=~\"http_server_requests(_total)?\", role=\"open-webui\", ${local.llm_chat_route}}[5m]))"
        legendFormat = "chats per 5m"
      }]
    },
    {
      title = "Chat response time p95 (Open WebUI)"
      unit  = "ms"
      targets = [{
        refId        = "A"
        datasource   = local.datasources.prometheus
        expr         = "histogram_quantile(0.95, sum by (le) (rate({__name__=~\"http_server_duration(_milliseconds)?_bucket\", role=\"open-webui\", ${local.llm_chat_route}}[5m])))"
        legendFormat = "p95"
      }]
    },
    {
      title = "Open WebUI requests by status"
      unit  = "reqps"
      targets = [{
        refId        = "A"
        datasource   = local.datasources.prometheus
        expr         = "sum by (http_status_code) (rate(${local.llm_owui_requests}[5m]))"
        legendFormat = "{{http_status_code}}"
      }]
    },
    {
      title = "Open WebUI response time"
      unit  = "ms"
      targets = [
        { refId = "A", datasource = local.datasources.prometheus, expr = "histogram_quantile(0.5, sum by (le) (rate(${local.llm_owui_duration}[5m])))", legendFormat = "p50" },
        { refId = "B", datasource = local.datasources.prometheus, expr = "histogram_quantile(0.95, sum by (le) (rate(${local.llm_owui_duration}[5m])))", legendFormat = "p95" },
      ]
    },
  ]

  llm_dashboard = {
    uid           = "llm"
    title         = "LLM and Open WebUI"
    tags          = ["task2", "llm"]
    timezone      = "browser"
    refresh       = "1m"
    schemaVersion = 39
    time          = { from = "now-3h", to = "now" }
    templating    = { list = [] }

    panels = concat(
      [
        for i, panel in local.llm_stats : {
          id         = 1 + i
          type       = "stat"
          title      = panel.title
          datasource = panel.target.datasource
          gridPos    = { h = 4, w = 4, x = i * 4, y = 0 }

          fieldConfig = {
            defaults = {
              unit       = panel.unit
              thresholds = { mode = "absolute", steps = panel.steps }
            }
            overrides = []
          }

          options = {
            colorMode     = "background"
            graphMode     = "none"
            reduceOptions = { calcs = [panel.calc], fields = "", values = false }
          }

          targets = [panel.target]
        }
      ],
      [
        for i, panel in local.llm_timeseries : {
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

resource "grafana_dashboard" "llm" {
  folder      = grafana_folder.llm.uid
  config_json = jsonencode(local.llm_dashboard)
  overwrite   = true
}
