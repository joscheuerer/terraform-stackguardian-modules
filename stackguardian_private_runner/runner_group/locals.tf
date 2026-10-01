locals {
  # Storage backend discriminator
  is_aws   = var.storage_backend.type == "aws_s3"
  is_azure = var.storage_backend.type == "azure_blob_storage"

  aws_backend   = var.storage_backend.aws
  azure_backend = var.storage_backend.azure

  create_azure_connector = local.is_azure && try(local.azure_backend.client_id, null) != null

  # Name of whichever connector this module created, or null when it created none
  connector_name = (
    local.is_aws ? stackguardian_connector.aws[0].resource_name
    : local.create_azure_connector ? stackguardian_connector.azure[0].resource_name
    : null
  )

  # Tags applied to both the runner group and the connector. The platform models
  # tags as a flat list of strings - there are no keys - so values are bare.
  #
  # Deliberately absent: the org name (a runner group only ever lives in one org)
  # and the runner group name (it is the resource's own name). Both were pure
  # duplication. The cloud account and prefix live here instead of in the name.
  default_tags = compact(concat(
    [
      "StackGuardian Private Runner",
      # Tool-agnostic on purpose: this module runs under both OpenTofu and
      # Terraform, and the tag's job is "do not hand-edit this in the console",
      # not to record which binary ran.
      "Managed by IaC",
      local.is_aws ? "aws" : "azure",
    ],
    var.tags,
  ))
}
