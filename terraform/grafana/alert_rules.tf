locals {
  host = "{{ $labels.instance }} ({{ $labels.role }})"

  promql = {
    cpu     = "100 * (1 - avg by (instance, role) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])))"
    memory  = "100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)"
    disk    = "max by (instance, role) (100 * (1 - node_filesystem_avail_bytes{mountpoint=\"/\"} / node_filesystem_size_bytes{mountpoint=\"/\"}))"
    service = "max by (instance, role) (node_systemd_unit_state{name=\"%s\", state=\"active\"})"
    rds_cpu = "max by (dimension_DBInstanceIdentifier) (aws_rds_cpuutilization_average)"
    rds_mem = "min by (dimension_DBInstanceIdentifier) (aws_rds_freeable_memory_average)"
    rds_sto = "min by (dimension_DBInstanceIdentifier) (aws_rds_free_storage_space_average)"
    alb_hhc = "min by (dimension_TargetGroup) (aws_applicationelb_healthy_host_count_minimum)"
    alb_4xx = "sum by (dimension_TargetGroup) (aws_applicationelb_httpcode_target_4_xx_count_sum)"
    alb_5xx = "sum by (dimension_TargetGroup) (aws_applicationelb_httpcode_target_5_xx_count_sum)"
  }

  ec2_rules = {
    "llm-test-ec2-low-cpu" = {
      expr      = local.promql.cpu
      operator  = "gt"
      threshold = 70
      severity  = "low"
      no_data   = "NoData"
      summary   = "CPU usage on ${local.host} is {{ humanize $values.A.Value }}%"
    }
    "llm-test-ec2-high-cpu" = {
      expr      = local.promql.cpu
      operator  = "gt"
      threshold = 90
      severity  = "high"
      no_data   = "NoData"
      summary   = "CPU usage on ${local.host} is {{ humanize $values.A.Value }}%"
    }
    "llm-test-ec2-low-memory" = {
      expr      = local.promql.memory
      operator  = "gt"
      threshold = 80
      severity  = "low"
      no_data   = "NoData"
      summary   = "Memory usage on ${local.host} is {{ humanize $values.A.Value }}%"
    }
    "llm-test-ec2-high-memory" = {
      expr      = local.promql.memory
      operator  = "gt"
      threshold = 90
      severity  = "high"
      no_data   = "NoData"
      summary   = "Memory usage on ${local.host} is {{ humanize $values.A.Value }}%"
    }
    "llm-test-ec2-low-disk-space" = {
      expr      = local.promql.disk
      operator  = "gt"
      threshold = 80
      severity  = "low"
      no_data   = "NoData"
      summary   = "Disk usage on / on ${local.host} is {{ humanize $values.A.Value }}%"
    }
    "llm-test-ec2-high-disk-space" = {
      expr      = local.promql.disk
      operator  = "gt"
      threshold = 90
      severity  = "high"
      no_data   = "NoData"
      summary   = "Disk usage on / on ${local.host} is {{ humanize $values.A.Value }}%"
    }
  }

  services = {
    alloy        = "alloy.service"
    ollama       = "ollama.service"
    ssh          = "ssh.socket"
    prometheus   = "prometheus.service"
    alertmanager = "prometheus-alertmanager.service"
    grafana      = "grafana-server.service"
    docker       = "docker.service"
    open-webui   = "open-webui.service"
  }

  service_rules = {
    for name, unit in local.services : "llm-test-ec2-service-${name}" => {
      expr      = format(local.promql.service, unit)
      operator  = "lt"
      threshold = 1
      severity  = "high"
      no_data   = "NoData"
      summary   = "${unit} is not active on ${local.host}"
    }
  }

  db_rules = {
    "llm-test-db-high-cpu" = {
      expr      = local.promql.rds_cpu
      operator  = "gt"
      threshold = 80
      severity  = "high"
      no_data   = "NoData"
      summary   = "RDS {{ $labels.dimension_DBInstanceIdentifier }} CPU is {{ humanize $values.A.Value }}%"
    }
    "llm-test-db-high-memory" = {
      expr      = local.promql.rds_mem
      operator  = "lt"
      threshold = 26214400
      severity  = "high"
      no_data   = "NoData"
      summary   = "RDS {{ $labels.dimension_DBInstanceIdentifier }} freeable memory is {{ humanize1024 $values.A.Value }}B"
    }
    "llm-test-db-high-storage" = {
      expr      = local.promql.rds_sto
      operator  = "lt"
      threshold = 2147483648
      severity  = "high"
      no_data   = "NoData"
      summary   = "RDS {{ $labels.dimension_DBInstanceIdentifier }} free storage is {{ humanize1024 $values.A.Value }}B"
    }
  }

  elb_rules = {
    "llm-test-elb-high-host-count" = {
      expr      = local.promql.alb_hhc
      operator  = "lt"
      threshold = 2
      severity  = "high"
      no_data   = "Alerting"
      summary   = "Healthy hosts in {{ $labels.dimension_TargetGroup }}: {{ $values.A.Value }}"
    }
    "llm-test-elb-medium-4XX-errors" = {
      expr      = local.promql.alb_4xx
      operator  = "gt"
      threshold = 50
      severity  = "medium"
      no_data   = "OK"
      summary   = "{{ $values.A.Value }} target 4XX responses in 5m on {{ $labels.dimension_TargetGroup }}"
    }
    "llm-test-elb-medium-5XX-errors" = {
      expr      = local.promql.alb_5xx
      operator  = "gt"
      threshold = 10
      severity  = "medium"
      no_data   = "OK"
      summary   = "{{ $values.A.Value }} target 5XX responses in 5m on {{ $labels.dimension_TargetGroup }}"
    }
  }

  rule_groups = {
    ec2 = merge(local.ec2_rules, local.service_rules)
    db  = local.db_rules
    elb = local.elb_rules
  }
}

resource "grafana_folder" "alerts" {
  title = "Alerts"
}

resource "grafana_rule_group" "this" {
  for_each         = local.rule_groups
  name             = each.key
  folder_uid       = grafana_folder.alerts.uid
  interval_seconds = 60

  dynamic "rule" {
    for_each = each.value

    content {
      name           = rule.key
      condition      = "C"
      for            = "5m"
      no_data_state  = rule.value.no_data
      exec_err_state = "Error"

      labels = {
        severity = rule.value.severity
      }

      annotations = {
        summary = rule.value.summary
      }

      data {
        ref_id         = "A"
        datasource_uid = grafana_data_source.prometheus.uid

        relative_time_range {
          from = 600
          to   = 0
        }

        model = jsonencode({
          refId   = "A"
          expr    = rule.value.expr
          instant = true
        })
      }

      data {
        ref_id         = "C"
        datasource_uid = "__expr__"

        relative_time_range {
          from = 0
          to   = 0
        }

        model = jsonencode({
          refId      = "C"
          type       = "threshold"
          expression = "A"
          conditions = [{
            evaluator = {
              type   = rule.value.operator
              params = [rule.value.threshold]
            }
          }]
        })
      }
    }
  }
}
