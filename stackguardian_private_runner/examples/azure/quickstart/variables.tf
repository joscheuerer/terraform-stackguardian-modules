/*-----------------------------------+
 | StackGuardian Platform Variables  |
 +-----------------------------------*/
variable "stackguardian" {
  description = "StackGuardian platform configuration (api_key, api_uri, org_name)"
  type = object({
    api_key  = string
    api_uri  = optional(string, "https://api.app.stackguardian.io")
    org_name = optional(string, "")
  })
  sensitive = true
}

/*---------------------+
 | Azure Configuration |
 +---------------------*/
variable "azure_location" {
  description = "Azure region for all resources"
  type        = string
  default     = "westeurope"
}

variable "azure_resource_group_name" {
  description = <<EOT
    Name of the resource group created for the whole deployment (storage backend,
    managed image, and runner VM).
    Leave empty to derive it from the prefix and subscription ID.
  EOT
  type        = string
  default     = ""
}

/*-------------------+
 | Resource Naming   |
 +-------------------*/
variable "override_names" {
  description = "Resource naming configuration"
  type = object({
    global_prefix         = string
    include_org_in_prefix = optional(bool, false)
    runner_group_name     = optional(string, "")
    connector_name        = optional(string, "")
  })
  default = {
    global_prefix = "SG_RUNNER"
  }
}

/*---------------------------+
 | Runner Group Settings     |
 +---------------------------*/
variable "max_runners" {
  description = "Maximum number of runners in the runner group"
  type        = number
  default     = 3
}

variable "azure_storage" {
  description = "Storage account configuration for the runner group storage backend"
  type = object({
    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, "LRS")
  })
  default = {}
}

variable "create_connector" {
  description = <<EOT
    Whether to create the Entra ID app registration and the StackGuardian OIDC
    connector for the storage backend. Set to false when you cannot create app
    registrations in Entra ID; the runner group then uses the storage account
    access key alone.
  EOT
  type        = bool
  default     = true
}

variable "create_role_assignments" {
  description = <<EOT
    Whether to create the two role assignments this deployment needs:
    'Storage Blob Data Reader' for the connector service principal, and
    'Storage Blob Data Contributor' for the runner's managed identity.
    Set to false when the identity running OpenTofu lacks
    Microsoft.Authorization/roleAssignments/write - you must then create both
    out of band before runners can use the storage backend.
  EOT
  type        = bool
  default     = true
}

/*---------------------------+
 | Image Build Settings      |
 +---------------------------*/
variable "vm_image_id" {
  description = <<EOT
    Existing managed image the runner VM boots instead of building one.
    Leave it empty to run the Packer module and build an image; set it to an
    image you already built (for example the image_id output of an earlier
    apply, or of the azure/packer example) and the build is skipped entirely -
    every other image build input below is then ignored.
    The image has to carry docker, cron, jq and sg-runner, and live in
    azure_location.
    Example: /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Compute/images/{name}
  EOT
  type        = string
  default     = ""

  validation {
    condition     = var.vm_image_id == "" || can(regex("^/subscriptions/", var.vm_image_id))
    error_message = "vm_image_id must be empty (build an image with Packer) or a valid Azure resource ID starting with '/subscriptions/'."
  }
}

variable "packer_vm_size" {
  description = "VM size for the Packer build instance"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "packer_network" {
  description = <<EOT
    Network for the Packer build VM.
    Leave vnet_name/subnet_name empty to let Packer create and destroy its own
    temporary networking; set them to build inside an existing VNet.
  EOT
  type = object({
    vnet_name           = optional(string, "")
    subnet_name         = optional(string, "")
    resource_group_name = optional(string, "")
    proxy_url           = optional(string, "")
  })
  default = {}
}

variable "os" {
  description = "Base Marketplace image for the runner image"
  type = object({
    publisher                = string
    offer                    = string
    sku                      = string
    version                  = optional(string, "latest")
    update_os_before_install = optional(bool, true)
    user_script              = optional(string, "")
  })
  default = {
    publisher                = "Canonical"
    offer                    = "0001-com-ubuntu-server-jammy"
    sku                      = "22_04-lts-gen2"
    version                  = "latest"
    update_os_before_install = true
  }
}

variable "packer_config" {
  description = <<EOT
    Packer build configuration.
    The image is built on the first apply and then reused on every following plan.
    To build a new one, change rebuild_image_token to any new value.
  EOT
  type = object({
    version                   = optional(string, "1.14.1")
    rebuild_image_token       = optional(string, "")
    cleanup_images_on_destroy = optional(bool, true)
  })
  default = {}
}

variable "sg_runner" {
  description = <<EOT
    StackGuardian runner script installation configuration.
    Set pre_release to true to bake the newest sg-runner pre-release into the
    image instead of the latest stable release; it falls back to the latest
    stable release when no pre-release exists.
    Changing this alone does not rebuild an existing image - also change
    packer_config.rebuild_image_token.
  EOT
  type = object({
    pre_release = optional(bool, false)
  })
  default = {}
}

variable "image_name_prefix" {
  description = "Prefix for the generated managed image name"
  type        = string
  default     = "sg-runner"
}

variable "terraform" {
  description = "Terraform versions to install in the runner image"
  type = object({
    primary_version     = optional(string, "")
    additional_versions = optional(list(string), [])
  })
  default = {}
}

variable "opentofu" {
  description = "OpenTofu versions to install in the runner image"
  type = object({
    primary_version     = optional(string, "")
    additional_versions = optional(list(string), [])
  })
  default = {}
}

/*---------------------------+
 | Runner VM Settings        |
 +---------------------------*/
variable "runner_vm_size" {
  description = "VM size for the Private Runner"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "os_disk" {
  description = "OS disk configuration for the runner VM"
  type = object({
    caching              = optional(string, "ReadWrite")
    storage_account_type = optional(string, "Premium_LRS")
    disk_size_gb         = optional(number, 100)
  })
  default = {}
}

variable "runner_startup_timeout" {
  description = "Seconds to wait for Docker to start before shutting down the VM"
  type        = number
  default     = 300
}

/*-------------------+
 | Network Settings  |
 +-------------------*/
variable "network" {
  description = <<EOT
    Existing VNet and subnet the runner VM attaches to. This example never creates
    networking - point it at a subnet you already have.

    - vnet_name / subnet_name: names of the existing VNet and subnet
    - resource_group_name: resource group holding that VNet
    - associate_public_ip: attach a static public IP to the runner. Keep it true
      unless the subnet already has its own route to the internet (NAT gateway,
      Azure Firewall, ExpressRoute) - the runner must reach the StackGuardian API.

    Service endpoints, NAT gateways and proxies belong to the subnet you bring:
    configure them there, or use the azure/azure_runner module directly.
  EOT
  type = object({
    vnet_name           = string
    subnet_name         = string
    resource_group_name = string
    associate_public_ip = optional(bool, true)
  })

  validation {
    condition = alltrue([
      trimspace(var.network.vnet_name) != "",
      trimspace(var.network.subnet_name) != "",
      trimspace(var.network.resource_group_name) != "",
    ])
    error_message = "network.vnet_name, network.subnet_name and network.resource_group_name are all required - this example attaches to an existing VNet and subnet."
  }
}

/*-------------------+
 | SSH Access        |
 +-------------------*/
variable "firewall" {
  description = <<EOT
    SSH and NSG configuration for the runner VM.
    Password authentication is always disabled, so one of ssh_public_key or
    generate_ssh_key is required. Prefer supplying your own public key -
    a generated key's private half is stored in state.
  EOT
  type = object({
    admin_username   = optional(string, "azureuser")
    ssh_public_key   = optional(string, "")
    generate_ssh_key = optional(bool, false)
    ssh_access_rules = optional(map(string), {})
    additional_inbound_rules = optional(map(object({
      priority                   = number
      direction                  = optional(string, "Inbound")
      access                     = optional(string, "Allow")
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = optional(string, "*")
    })), {})
  })
  default = {
    generate_ssh_key = true
  }
}
