# ============================================================
# StackGuardian Private Runner - Azure Quickstart
# ============================================================
# Copy this file to terraform.tfvars and fill in your values.
# Everything commented out is optional and shown with its default.
# ============================================================

# --- Required: StackGuardian credentials ---
stackguardian = {
  #api_key  = "sgu_2545cGRV1dxMquuZJLwI5" # Your SG API key
  org_name = "wicked-hop"                    # Your SG organization name
   api_uri = "https://api.app.stackguardian.io"  # EU1 (default)
  # api_uri = "https://api.us.stackguardian.io"   # US1
}

# --- Required in practice: SSH access ---
# Password auth is always disabled, so the VM needs a key. Supply your own
# public key here; the alternative, generate_ssh_key = true, is the default
# only so the example applies out of the box - it puts the private key in state.
firewall = {
  ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHeJlnW8IWxJaLhDqKC0W6xEdSZgsuf9YZ996OeAEmz8 joscheuerer@Jos-MacBook-Air.fritz.box"
  admin_username = "azureuser"
  #
  # Nothing is open inbound unless you add a rule. Port 22 from one address:
  ssh_access_rules = {
   "my-ip" = "203.0.113.10/32"
   }
  #
  # additional_inbound_rules = {
  #   "custom" = {
  #     priority               = 200
  #     protocol               = "Tcp"
  #     destination_port_range = "8080"
  #     source_address_prefix  = "10.0.0.0/8"
  #   }
  # }
}

# --- Required: Existing network ---
# This example attaches the runner to a VNet and subnet you already have; it
# never creates networking. The subnet needs outbound access to the
# StackGuardian API, either through the public IP below or through its own
# route (NAT gateway, Azure Firewall, ExpressRoute).
network = {
  vnet_name           = "joVnet-do-not-delete"
  subnet_name         = "subnet2"
  resource_group_name = "jo-test"
  #
  # Set to false when the subnet already provides outbound internet access.
  associate_public_ip = true
}

# --- Optional: Azure placement ---
# Must be the same region as the VNet above: the NIC joins its subnet and the
# VM boots from an image built in this region.
azure_location = "germanywestcentral"
#
# One resource group holds the storage backend, the managed image, and the VM.
# Leave empty to derive the name from the prefix and subscription ID.
azure_resource_group_name = "jo-test-runner"

# --- Optional: Resource naming ---
#
# The runner group and connector are named {global_prefix}-{runner_group_name}.
# Leave runner_group_name empty and a short random suffix is generated, e.g.
# SG_RUNNER-k3m9xz. The cloud account ID and region are recorded as tags.
override_names = {
    global_prefix         = "JO_RUNNER"
   include_org_in_prefix = false  # affects the VM/NSG names only, not the runner group
#   runner_group_name     = ""  # default: a 6-char random suffix
#   connector_name        = ""  # default: same as the runner group name
 }

# --- Optional: Runner group and storage backend ---
max_runners = 3
 azure_storage = {
   account_tier             = "Standard"
   account_replication_type = "LRS"
}
#
# Set to false if the identity running OpenTofu cannot write role assignments
# (Contributor without User Access Administrator). You must then grant
# "Storage Blob Data Reader" to the connector service principal and
# "Storage Blob Data Contributor" to the runner identity yourself.
 create_role_assignments = true
#
# Set to false if you cannot create app registrations in Entra ID. No Entra
# app or StackGuardian OIDC connector is created; the runner group reaches the
# storage account with its access key instead.
 create_connector = true

# --- Optional: Image build ---
#
# Already have a runner image? Set vm_image_id and nothing below is built or
# used - no Packer, no build VM, no destroy-time image cleanup. It has to live
# in azure_location and carry docker, cron, jq and sg-runner. Set it on a fresh
# deployment; see the README before adding it to a deployment that already
# built an image.
# vm_image_id = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Compute/images/<name>"
#
 packer_vm_size    = "Standard_D2s_v3"
 image_name_prefix = "sg-runner"
#
# Bake the newest sg-runner pre-release into the image instead of the latest
# stable release; falls back to stable when none exists. Needs a rebuild to
# take effect - bump rebuild_image_token too.
 sg_runner = {
   pre_release = false
 }
#
# Packer builds the image on the first apply only. Later plans reuse it, so the
# runner keeps the same image. To build a new one, change the token below to
# any new value:
 packer_config = {
   version                   = "1.14.1"
   rebuild_image_token       = "2026-08-24"
   cleanup_images_on_destroy = true
 }
#
# Base Marketplace image. publisher must be "Canonical" or "RedHat".
 os = {
   publisher                = "Canonical"
   offer                    = "0001-com-ubuntu-server-jammy"
   sku                      = "22_04-lts-gen2"
   version                  = "latest"
   update_os_before_install = true
   user_script              = ""  # extra shell run after standard setup
 }
#
 terraform = {
   primary_version     = "1.9.8"
   additional_versions = ["1.8.5"]
 }
 opentofu = {
   primary_version = "1.8.8"
 }
#
# By default Packer builds on its own throwaway VNet. Point it at an existing
# one when the build must run inside your network:
# packer_network = {
#   vnet_name           = "my-vnet"
#   subnet_name         = "build-subnet"
#   resource_group_name = "my-network-rg"
#   proxy_url           = ""
# }

# --- Optional: Runner VM ---
 runner_vm_size = "Standard_D4s_v3"
 os_disk = {
   caching              = "ReadWrite"
   storage_account_type = "Premium_LRS"
   disk_size_gb         = 100
 }
# Seconds to wait for Docker to come up before the VM shuts itself down.
# Raise it if a custom user_script makes first boot slow.
# runner_startup_timeout = 300
