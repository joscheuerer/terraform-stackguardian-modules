/*-----------------------------------+
 | StackGuardian Platform Variables  |
 +-----------------------------------*/
variable "sg_org_name" {
  description = "StackGuardian organization name, resolved by the calling module."
  type        = string

  validation {
    condition     = var.sg_org_name != ""
    error_message = "sg_org_name must not be empty. Set stackguardian.org_name on the calling module or make sure SG_ORG_ID is exported."
  }
}

variable "sg_app_uri" {
  description = "StackGuardian web console base URI, resolved by the calling module (e.g. https://app.stackguardian.io). Used to build the runner group URL output."
  type        = string
}

/*---------------------------+
 | Runner Group & Connector  |
 +---------------------------*/
variable "runner_group_name" {
  description = "Name of the StackGuardian runner group to create."
  type        = string
}

variable "connector_name" {
  description = "Name of the StackGuardian connector to create for storage backend access."
  type        = string
}

variable "tags" {
  description = <<EOT
    Extra tags for the runner group and the connector, appended to the ones this
    module always sets ("StackGuardian Private Runner", "Managed by IaC", and
    the cloud name). The calling module passes cloud-specific values here -
    account or subscription ID, region, and the naming prefix.

    The platform models tags as a flat list of strings, not key/value pairs, and
    allows at most 10 in total.
  EOT
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.tags) <= 7
    error_message = "At most 7 extra tags: the platform caps tags at 10 and this module already sets 3."
  }
}

variable "max_runners" {
  description = "Maximum number of runners allowed in the runner group"
  type        = number
  default     = 3

  validation {
    condition     = var.max_runners >= 1
    error_message = "max_runners must be at least 1."
  }
}

/*---------------------------+
 | Storage Backend           |
 +---------------------------*/
variable "storage_backend" {
  description = <<EOT
    Resolved storage backend the runner group and connector are wired to. The cloud
    resources themselves are created by the calling module (aws/runner_group or
    azure/runner_group); this module only registers them with the platform.

    - type: "aws_s3" or "azure_blob_storage"
    - aws: required when type = "aws_s3" — bucket name plus the cross-account role
      and external ID the AWS_RBAC connector assumes
    - azure: required when type = "azure_blob_storage" — storage account name and
      access key plus the identity the AZURE_OIDC connector federates with
      (client_id = null creates no connector)
  EOT
  type = object({
    type = string
    aws = optional(object({
      region      = string
      bucket_name = string
      role_arn    = string
      external_id = string
    }))
    azure = optional(object({
      storage_account_name = string
      access_key           = string
      tenant_id            = string
      subscription_id      = string
      # null skips the AZURE_OIDC connector: an Azure Blob backend authenticates
      # with the access key alone, so the connector is optional there
      client_id = optional(string)
    }))
  })

  validation {
    condition     = contains(["aws_s3", "azure_blob_storage"], var.storage_backend.type)
    error_message = "storage_backend.type must be either 'aws_s3' or 'azure_blob_storage'."
  }

  validation {
    condition     = var.storage_backend.type != "aws_s3" || var.storage_backend.aws != null
    error_message = "storage_backend.aws is required when storage_backend.type = 'aws_s3'."
  }

  validation {
    condition     = var.storage_backend.type != "azure_blob_storage" || var.storage_backend.azure != null
    error_message = "storage_backend.azure is required when storage_backend.type = 'azure_blob_storage'."
  }
}
