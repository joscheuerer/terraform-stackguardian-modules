/*---------------------------+
 | Storage Backend Options   |
 +---------------------------*/
variable "create_storage_backend" {
  description = <<EOT
    Whether to create a new Storage Account as the storage backend.
    Set to false to use an existing one passed via existing_azure_storage_account_name.
  EOT
  type        = bool
  default     = true
}

variable "existing_azure_storage_account_name" {
  description = "Name of an existing Azure Storage Account to use as storage backend (required when create_storage_backend = false)"
  type        = string
  default     = ""
}

variable "existing_azure_storage_account_access_key" {
  description = "Access key for the existing Azure Storage Account (required when create_storage_backend = false)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_storage" {
  description = <<EOT
    Azure Storage Account configuration (used when create_storage_backend = true).

    - account_tier: Performance tier of the storage account (Standard or Premium)
    - account_replication_type: Replication strategy (LRS, GRS, RAGRS, ZRS)
  EOT
  type = object({
    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, "LRS")
  })
  default = {
    account_tier             = "Standard"
    account_replication_type = "LRS"
  }

  validation {
    condition     = contains(["Standard", "Premium"], var.azure_storage.account_tier)
    error_message = "The account_tier must be either 'Standard' or 'Premium'."
  }

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS"], var.azure_storage.account_replication_type)
    error_message = "The account_replication_type must be one of: LRS, GRS, RAGRS, ZRS."
  }
}

/*---------------------------+
 | Azure Platform Variables  |
 +---------------------------*/
variable "azure_location" {
  description = "The Azure region where resources will be deployed"
  type        = string
  default     = "westeurope"
}

variable "create_azure_resource_group" {
  description = <<EOT
    Whether to create a new Azure Resource Group to host the storage account (and to be reused by downstream azure/* modules via the azure_resource_group_name output).
    Set to false to deploy the storage account into an existing resource group passed via azure_resource_group_name.
  EOT
  type        = bool
  default     = true
}

variable "azure_resource_group_name" {
  description = <<EOT
    Name of the Azure Resource Group used by the module.

    - When create_azure_resource_group = true (default), this is an optional override for the new resource group's name. If left empty, the name is derived from override_names.global_prefix and the subscription ID.
    - When create_azure_resource_group = false, this must be the name of an existing resource group to deploy the storage account into.
  EOT
  type        = string
  default     = ""
}

variable "create_connector" {
  description = <<EOT
    Whether to create the Azure AD app registration, service principal and federated
    credential, and the StackGuardian AZURE_OIDC connector backed by them.
    Set to false when the identity running Terraform cannot create app registrations
    in Entra ID. The runner group then reaches the storage account with its access
    key alone, and no 'Storage Blob Data Reader' role assignment is created.
  EOT
  type        = bool
  default     = true
}

variable "create_blob_reader_role_assignment" {
  description = <<EOT
    Whether to create the 'Storage Blob Data Reader' role assignment that grants the OIDC connector service principal read access to the storage account.
    Set to false when the identity running Terraform lacks Microsoft.Authorization/roleAssignments/write (e.g. Contributor without User Access Administrator). When false, you must create the role assignment out of band before runners can read from the storage account.
  EOT
  type        = bool
  default     = true
}

/*-----------------------------------+
 | StackGuardian Platform Variables  |
 +-----------------------------------*/
variable "stackguardian" {
  description = "StackGuardian platform configuration"
  type = object({
    api_key  = string
    api_uri  = optional(string, "https://api.app.stackguardian.io")
    org_name = optional(string, "")
  })
  sensitive = true

  validation {
    condition     = can(regex("^sg[uo]_.*", var.stackguardian.api_key))
    error_message = "The api_key must be a valid StackGuardian API key starting with 'sgu_' (user) or 'sgo_' (organization)."
  }

  validation {
    condition = contains([
      "https://api.app.stackguardian.io",
      "https://api.us.stackguardian.io",
      "https://testapi.qa.stackguardian.io"
    ], var.stackguardian.api_uri)
    error_message = "The api_uri must be either 'https://api.app.stackguardian.io' (EU1), 'https://api.us.stackguardian.io' (US1) or 'https://testapi.qa.stackguardian.io' (DASH)."
  }
}

/*-------------------+
 | General Variables |
 +-------------------*/
variable "override_names" {
  description = <<EOT
    Naming for the StackGuardian runner group and connector.

    Both are named {global_prefix}-{name}, or just {name} when global_prefix is
    empty. The cloud subscription ID and the prefix are recorded as tags
    rather than baked into the name.

    - global_prefix: Prefix for the runner group and connector names. Set to ""
      to omit it entirely.
    - runner_group_name: Name half of the runner group. Generated as a short
      random string when left empty.
    - connector_name: Name half of the connector. Defaults to the runner group's,
      so the pair share a name - they live in separate API namespaces.
  EOT
  type = object({
    global_prefix     = string
    runner_group_name = optional(string, "")
    connector_name    = optional(string, "")
  })
  default = {
    global_prefix = "SG_RUNNER"
  }
}

/*----------------------------+
 | Runner Group Configuration |
 +----------------------------*/
variable "max_runners" {
  description = "Maximum number of runners allowed in the runner group"
  type        = number
  default     = 3

  validation {
    condition     = var.max_runners >= 1
    error_message = "max_runners must be at least 1."
  }
}
