# StackGuardian Connector (storage backend authentication)
#
# Both variants are plain platform resources: the cloud identities they point at are
# created by the calling module and arrive here as strings, so this module needs no
# AWS or Azure provider.

# AWS Connector — Uses RBAC role for S3 access
resource "stackguardian_connector" "aws" {
  count = local.is_aws ? 1 : 0

  resource_name = var.connector_name
  description   = "AWS connector for accessing Private Runner storage backend (S3 Bucket: ${local.aws_backend.bucket_name})."

  settings = {
    kind = "AWS_RBAC"

    config = [{
      role_arn         = local.aws_backend.role_arn
      external_id      = local.aws_backend.external_id
      duration_seconds = "3600"
    }]
  }

  tags = local.default_tags
}

# Azure Connector — Uses OIDC with a Service Principal provisioned by the caller
resource "stackguardian_connector" "azure" {
  count = local.create_azure_connector ? 1 : 0

  resource_name = var.connector_name
  description   = "Azure OIDC connector for Private Runner storage backend"

  settings = {
    kind = "AZURE_OIDC"

    config = [{
      arm_tenant_id       = local.azure_backend.tenant_id
      arm_subscription_id = local.azure_backend.subscription_id
      arm_client_id       = local.azure_backend.client_id
    }]
  }

  tags = local.default_tags
}
