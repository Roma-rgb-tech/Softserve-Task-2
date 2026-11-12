resource "terraform_data" "external_alertmanager" {
  input            = "external"
  triggers_replace = data.terraform_remote_state.infra.outputs.grafana_url

  provisioner "local-exec" {
    command = "curl -fsS -u \"admin:$GRAFANA_PASSWORD\" -H 'Content-Type: application/json' -X POST -d '{\"alertmanagersChoice\":\"${self.input}\"}' ${data.terraform_remote_state.infra.outputs.grafana_url}/api/v1/ngalert/admin_config"

    environment = {
      GRAFANA_PASSWORD = data.aws_ssm_parameter.grafana_admin_password.value
    }
  }

  depends_on = [grafana_data_source.alertmanager]
}
