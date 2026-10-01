/*---------------------------------+
 | Runner Group Outputs             |
 +---------------------------------*/
output "runner_group_name" {
  description = "The name of the StackGuardian runner group"
  value       = module.runner_group.runner_group_name
}

output "runner_group_id" {
  description = "The ID of the StackGuardian runner group"
  value       = module.runner_group.runner_group_id
}

output "runner_group_token" {
  description = "The token for runner registration (sensitive)"
  sensitive   = true
  value       = module.runner_group.runner_group_token
}

output "runner_group_url" {
  description = "Direct URL to the runner group in the StackGuardian web console"
  value       = module.runner_group.runner_group_url
}

/*---------------------------------+
 | Connector Outputs                |
 +---------------------------------*/
output "connector_name" {
  description = "The name of the StackGuardian Azure connector"
  value       = module.runner_group.connector_name
}

output "connector_id" {
  description = "The ID of the StackGuardian Azure connector"
  value       = module.runner_group.connector_id
}

output "azure_connector_service_principal_object_id" {
  description = "Object ID of the OIDC connector service principal (null when create_connector = false). Use this to create the 'Storage Blob Data Reader' role assignment out of band when create_blob_reader_role_assignment = false."
  value       = var.create_connector ? azuread_service_principal.connector[0].object_id : null
}

/*---------------------------------+
 | Storage Backend Outputs          |
 +---------------------------------*/
output "azure_resource_group_name" {
  description = "The name of the Azure Resource Group containing the storage account. Pass this to downstream azure/* modules' resource_group_name input."
  value       = local.resource_group_name
}

output "azure_resource_group_location" {
  description = "The location of the Azure Resource Group"
  value       = var.azure_location
}

output "azure_storage_account_name" {
  description = "The name of the Azure Storage Account used for storage backend"
  value       = local.storage_account_name
}

output "azure_storage_account_id" {
  description = "The resource ID of the Azure Storage Account used for storage backend (null when using an existing account)"
  value       = var.create_storage_backend ? azurerm_storage_account.this[0].id : null
}

output "azure_storage_access_key" {
  description = "The access key for the Azure Storage Account (sensitive)"
  sensitive   = true
  value       = local.storage_access_key
}

/*---------------------------------+
 | StackGuardian Platform Outputs  |
 +---------------------------------*/
output "sg_org_name" {
  description = "The StackGuardian organization name"
  value       = local.sg_org_name
}

output "sg_api_uri" {
  description = "The StackGuardian API URI"
  value       = local.sg_api_uri
}

output "azure_location" {
  description = "The Azure region"
  value       = var.azure_location
}
