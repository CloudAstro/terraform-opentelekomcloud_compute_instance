variable "admin_pass" {
  sensitive   = true
  type        = string
  default     = null
  description = <<DESCRIPTION
Optional administrator password. Prefer SSH keys where supported. Sensitive values are still stored in Terraform state.
DESCRIPTION
}

variable "auto_recovery" {
  type        = bool
  default     = null
  description = <<DESCRIPTION
Whether the compute service automatically recovers the instance after a host failure. Null uses the provider default.
DESCRIPTION
}

variable "availability_zone" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Availability zone for the instance, for example eu-de-01. Attached volumes must use a compatible zone.
DESCRIPTION
}

variable "config_drive" {
  type        = bool
  default     = null
  description = <<DESCRIPTION
Whether to enable a configuration drive for instance metadata. Null uses the provider default.
DESCRIPTION
}

variable "description" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Optional instance description.
DESCRIPTION
}

variable "flavor_id" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Compute flavor ID. Supply exactly one of flavor_id or flavor_name.
DESCRIPTION

  validation {
    condition     = length(compact([var.flavor_id, var.flavor_name])) == 1
    error_message = "Supply exactly one of flavor_id or flavor_name."
  }
}

variable "flavor_name" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Compute flavor name. Supply exactly one of flavor_id or flavor_name.
DESCRIPTION
}

variable "image_id" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Image UUID for image boot, or the fallback UUID for image-backed block devices. Mutually exclusive with image_name and image_reference.
DESCRIPTION
}

variable "image_name" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Image name for image boot. Prefer a pinned image_id for reproducible deployments. Volume-backed boot requires disk UUIDs or image_id/image_reference.
DESCRIPTION
}

variable "key_pair" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Name of an existing key pair. Do not combine with a non-empty compute_keypair map.
DESCRIPTION
}

variable "metadata" {
  type        = map(string)
  default     = null
  description = <<DESCRIPTION
Optional instance metadata. Do not store credentials in metadata.
DESCRIPTION
}

variable "name" {
  type        = string
  nullable    = false
  description = <<DESCRIPTION
Instance name. Must not be empty.
DESCRIPTION

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must not be empty."
  }
}

variable "power_state" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Desired instance state: active or shutoff. Null uses the provider default.
DESCRIPTION

  validation {
    condition     = var.power_state == null ? true : contains(["active", "shutoff"], var.power_state)
    error_message = "power_state must be active or shutoff."
  }
}

variable "region" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Optional region override for compute, key pairs, block storage and attachments. Image lookup and EVS v3 use the provider region; use a provider alias consistently for deployments in another region.
DESCRIPTION
}

variable "security_groups" {
  type        = set(string)
  default     = null
  description = <<DESCRIPTION
Security group names for network-based attachments. With pre-created ports, configure groups on the ports instead.
DESCRIPTION
}

variable "ssh_private_key_path" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Optional local private-key path used by the provider for password operations. The file must exist on the machine running Terraform.
DESCRIPTION
}

variable "stop_before_destroy" {
  type        = bool
  default     = null
  description = <<DESCRIPTION
Whether to request a graceful stop before deleting the instance.
DESCRIPTION
}

variable "tags" {
  type        = map(string)
  default     = null
  description = <<DESCRIPTION
Optional instance tags.
DESCRIPTION
}

variable "user_data" {
  sensitive   = true
  type        = string
  default     = null
  description = <<DESCRIPTION
Cloud-init or other instance boot configuration. Changes can replace the instance. Marked sensitive to avoid displaying its contents; it remains in Terraform state.
DESCRIPTION
}

variable "block_device" {
  type = list(object({
    boot_index            = optional(number)
    delete_on_termination = optional(bool)
    destination_type      = optional(string)
    guest_format          = optional(string)
    source_type           = string
    uuid                  = optional(string)
    volume_size           = optional(number)
    volume_type           = optional(string)
  }))
  default     = null
  description = <<DESCRIPTION
Optional block devices in attachment order. Set boot_index = 0 for the boot disk and destination_type = "volume" for volume-backed boot. Each explicit uuid is preserved; image sources without a uuid use image_id or image_reference. guest_format is forwarded to the provider. os_disk was unused and has been removed. The first block device's UUID and size retain the existing ignore_changes behavior.
DESCRIPTION
}

variable "network" {
  nullable = false
  type = list(object({
    access_network = optional(bool)
    fixed_ip_v4    = optional(string)
    fixed_ip_v6    = optional(string)
    port           = optional(string)
    uuid           = optional(string)
    name           = optional(string)
  }))
  default     = []
  description = <<DESCRIPTION
Ordered network attachments. Each entry selects exactly one of uuid (network ID), name or port. Optional fixed_ip_v4, fixed_ip_v6 and access_network are forwarded. The unused mac input has been removed because the provider computes it. An empty list leaves network selection to the service.
DESCRIPTION

  validation {
    condition     = alltrue([for entry in var.network : try(length(compact([entry.uuid, entry.name, entry.port])) == 1, false)])
    error_message = "Each network must select exactly one of uuid, name or port."
  }
}

variable "scheduler_hints" {
  type = set(object({
    build_near_host_ip = optional(string)
    deh_id             = optional(string)
    different_host     = optional(list(string))
    group              = optional(string)
    query              = optional(list(string))
    same_host          = optional(list(string))
    target_cell        = optional(string)
    tenancy            = optional(string)
  }))
  default     = null
  description = <<DESCRIPTION
Optional set containing at most one scheduling-hints object. Supports server group, host affinity, query, cell, tenancy and dedicated-host ID. Availability depends on the cloud deployment.
DESCRIPTION

  validation {
    condition     = var.scheduler_hints == null ? true : length(var.scheduler_hints) <= 1
    error_message = "scheduler_hints supports at most one object."
  }
}

variable "timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Instance operation timeouts, for example { create = "30m", update = "30m", delete = "30m" }.
DESCRIPTION
}


# compute_keypair_v2
variable "compute_keypair" {
  type = map(object({
    name        = string
    public_key  = optional(string)
    value_specs = optional(map(string))
  }))
  default     = null
  description = <<DESCRIPTION
Optional map with at most one key-pair definition. The map key is accepted for compatibility; the resource address remains ["this"]. Supply public_key to import an existing public key. If omitted, the provider generates a key pair and stores its private key in state. Use key_pair instead to select an existing key pair.
DESCRIPTION

  validation {
    condition     = length(coalesce(var.compute_keypair, {})) <= 1 && (length(coalesce(var.compute_keypair, {})) == 0 || var.key_pair == null)
    error_message = "Supply at most one compute_keypair entry and do not combine it with key_pair."
  }
}

variable "image_reference" {
  type = object({
    name_regex  = string
    most_recent = bool
    visibility  = string
  })
  default     = null
  description = <<DESCRIPTION
Optional image lookup by name_regex, most_recent and visibility. Mutually exclusive with image_id and image_name. Catalog changes can change the selected image; prefer a pinned image_id for reproducibility.
DESCRIPTION

  validation {
    condition     = length(compact([var.image_id, var.image_name])) + (var.image_reference == null ? 0 : 1) <= 1
    error_message = "Use only one of image_id, image_name or image_reference."
  }
}

# evs_volume_v3
variable "evs_volume" {
  type = map(object({
    availability_zone = string
    backup_id         = optional(string)
    cascade           = optional(bool)
    description       = optional(string)
    device_type       = optional(string)
    image_id          = optional(string)
    kms_id            = optional(string)
    multiattach       = optional(bool)
    name              = optional(string)
    size              = optional(number)
    snapshot_id       = optional(string)
    tags              = optional(map(string))
    volume_type       = string
    compute_volume_attach = optional(object({
      device = optional(string)
    }), {})
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
    }))
  }))
  default     = null
  description = <<DESCRIPTION
Optional EVS v3 data volumes, keyed by stable names. Each volume is created and attached to this instance. Supports volume type, size, image/backup/snapshot sources, encryption via kms_id and tags. compute_volume_attach.device optionally requests a guest device; instance_id and volume_id are derived internally. timeouts applies to both volume creation/deletion and attachment/detachment. Guest formatting and mounting are not managed.
DESCRIPTION
}


variable "blockstorage_volume" {
  type = map(object({
    availability_zone    = string
    consistency_group_id = optional(string)
    description          = optional(string)
    image_id             = optional(string)
    metadata             = optional(map(string))
    name                 = optional(string)
    size                 = number
    snapshot_id          = optional(string)
    source_replica       = optional(string)
    source_vol_id        = optional(string)
    tags                 = optional(map(string))
    volume_type          = string
    device_type          = optional(string)
    cascade              = optional(bool, false)
    compute_volume_attach = optional(object({
      device = optional(string)
    }), {})
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
    }))
  }))
  default     = null
  description = <<DESCRIPTION
Optional Block Storage v2 data volumes, keyed by stable names. Each volume is created and attached to this instance. Supports source volumes, snapshots, images, metadata and tags. compute_volume_attach.device optionally requests a guest device; instance_id and volume_id are derived internally. timeouts applies to both volume creation/deletion and attachment/detachment. Guest formatting and mounting are not managed.
DESCRIPTION
}