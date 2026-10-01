/*---------------------------------+
 | Runner Group Outputs             |
 +---------------------------------*/
output "runner_group_name" {
  description = "The name of the StackGuardian runner group"
  value       = stackguardian_runner_group.this.resource_name
}

output "runner_group_id" {
  description = "The ID of the StackGuardian runner group"
  value       = stackguardian_runner_group.this.resource_name
}

output "runner_group_token" {
  description = "The token for runner registration (sensitive)"
  sensitive   = true
  value       = data.stackguardian_runner_group_token.this.runner_group_token
}

output "runner_group_url" {
  description = "Direct URL to the runner group in the StackGuardian web console"
  value       = "${var.sg_app_uri}/orchestrator/orgs/${var.sg_org_name}/runnergroups/${stackguardian_runner_group.this.resource_name}"
}

/*---------------------------------+
 | Connector Outputs                |
 +---------------------------------*/
output "connector_name" {
  description = "The name of the StackGuardian connector (null when no Azure connector was created)"
  value       = local.connector_name
}

output "connector_id" {
  description = "The ID of the StackGuardian connector (null when no Azure connector was created)"
  value       = local.connector_name
}
