# Runner Group (shared, cloud-agnostic)

> Part of [StackGuardian Private Runner](../README.md) — internal module, not deployed directly.

Internal module. Registers a StackGuardian Runner Group and its storage-backend
connector with the platform.

**You almost certainly want a wrapper instead:**

- [`aws/runner_group/`](../aws/runner_group/) — S3 backend, `AWS_RBAC` connector
- [`azure/runner_group/`](../azure/runner_group/) — Blob Storage backend, `AZURE_OIDC`
  connector

## Why this module exists

Terraform provider requirements are static: there is no conditional
`required_providers`, and `count = 0` does not stop a provider from being installed and
configured. A single module holding both the AWS and Azure storage backends therefore
forces every caller to install and configure *both* clouds' providers — an AWS user would
need `azurerm` credentials just to create an S3 bucket.

So the cloud resources live in the per-cloud wrappers, and everything they have in common
— the platform resources, which need no cloud provider at all — lives here. This module
requires only the `stackguardian` provider. Verify with `tofu providers` in either
wrapper: the AWS one never mentions `azurerm`/`azuread`, and the Azure one never mentions
`aws`.

## What it creates

- `stackguardian_runner_group` with the resolved storage backend configuration
- `stackguardian_connector` — `AWS_RBAC` or `AZURE_OIDC`, chosen by
  `storage_backend.type`
- Reads `stackguardian_runner_group_token` for runner registration

Everything cloud-side — buckets, storage accounts, IAM roles, Entra ID apps — is created
by the caller and passed in as strings.

## Interface

The caller resolves names and identities, then hands over a discriminated
`storage_backend` object:

```hcl
module "runner_group" {
  source = "../../runner_group"

  sg_org_name = local.sg_org_name
  sg_app_uri  = local.sg_app_uri

  runner_group_name = local.runner_group_name
  connector_name    = local.connector_name
  max_runners       = var.max_runners

  storage_backend = {
    type = "aws_s3"
    aws = {
      region      = var.aws_region
      bucket_name = local.s3_bucket_name
      role_arn    = aws_iam_role.storage_backend.arn
      external_id = local.connector_external_id
    }
  }
}
```

The Azure shape instead sets `type = "azure_blob_storage"` and populates `azure` with
`storage_account_name`, `access_key`, `tenant_id`, `subscription_id`, and, for the
optional AZURE_OIDC connector, `create_connector = true` plus `client_id`. The connector
is gated on the `create_connector` bool rather than on `client_id`, so its count is
known at plan time even when `client_id` comes from an app registration created in
the same apply.
Variable validation enforces that the sub-object matching `type` is present.

### Inputs

| Variable | Description |
|----------|-------------|
| `sg_org_name` | Organization name, already resolved (from `stackguardian.org_name` or `SG_ORG_ID`) |
| `sg_app_uri` | Web console base URI, used to build `runner_group_url` |
| `runner_group_name` | Final runner group name |
| `connector_name` | Final connector name |
| `max_runners` | Maximum runners in the group (default `3`) |
| `storage_backend` | Discriminated backend config — see above |

### Outputs

| Output | Description |
|--------|-------------|
| `runner_group_name` / `runner_group_id` | Name of the created runner group |
| `runner_group_token` | Registration token (sensitive) |
| `runner_group_url` | Direct link to the runner group in the web console |
| `connector_name` / `connector_id` | Name of the created connector |

## Provider configuration

This module declares no `provider` block — the wrapper's `provider "stackguardian"` is
inherited. Keeping provider configuration out of child modules is deliberate: a module
that configures its own providers is a *legacy module* and cannot take `count`,
`for_each`, or `depends_on`.

## Adding a cloud

1. Add a branch to `storage_backend` in `variables.tf`, with a validation rule requiring
   its sub-object when `type` matches.
2. Add the matching `stackguardian_connector` resource in `connector.tf` and a branch in
   `runner_group.tf`.
3. Create a `{cloud}/runner_group/` wrapper that builds the cloud resources and calls this
   module. It should require only that cloud's providers.
