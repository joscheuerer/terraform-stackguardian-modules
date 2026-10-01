# StackGuardian Runner Group

resource "stackguardian_runner_group" "this" {
  resource_name = var.runner_group_name
  description   = "Private Runner Group for ${local.is_aws ? "AWS S3" : "Azure Blob Storage"} storage backend"

  max_number_of_runners = var.max_runners

  storage_backend_config = local.is_aws ? {
    type                            = "aws_s3"
    aws_region                      = local.aws_backend.region
    s3_bucket_name                  = local.aws_backend.bucket_name
    azure_blob_storage_account_name = null
    azure_blob_storage_access_key   = null
    auth = {
      integration_id = "/integrations/${stackguardian_connector.aws[0].resource_name}"
    }
    } : {
    type                            = "azure_blob_storage"
    aws_region                      = null
    s3_bucket_name                  = null
    azure_blob_storage_account_name = local.azure_backend.storage_account_name
    azure_blob_storage_access_key   = local.azure_backend.access_key
    auth = local.create_azure_connector ? {
      integration_id = "/integrations/${stackguardian_connector.azure[0].resource_name}"
    } : null
  }

  tags = local.default_tags
}
