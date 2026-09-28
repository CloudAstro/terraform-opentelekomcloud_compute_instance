resource "opentelekomcloud_compute_instance_v2" "compute_instance_v2" {
  name                 = var.name
  description          = var.description
  region               = var.region
  image_id             = local.boot_from_volume ? null : local.image_id
  image_name           = local.boot_from_volume || local.image_id != null ? null : var.image_name
  flavor_id            = var.flavor_id
  flavor_name          = var.flavor_name
  user_data            = var.user_data
  ssh_private_key_path = var.ssh_private_key_path
  security_groups      = var.security_groups
  availability_zone    = var.availability_zone
  metadata             = var.metadata
  config_drive         = var.config_drive
  admin_pass           = var.admin_pass
  key_pair             = try(opentelekomcloud_compute_keypair_v2.compute_instance_v2["this"].name, var.key_pair)
  tags                 = var.tags
  stop_before_destroy  = var.stop_before_destroy
  auto_recovery        = var.auto_recovery
  power_state          = var.power_state

  dynamic "block_device" {
    for_each = var.block_device != null ? var.block_device : []
    content {
      uuid                  = block_device.value.uuid != null ? block_device.value.uuid : (block_device.value.source_type == "image" ? local.image_id : null)
      guest_format          = block_device.value.guest_format
      source_type           = block_device.value.source_type
      volume_size           = block_device.value.volume_size
      volume_type           = block_device.value.volume_type
      boot_index            = block_device.value.boot_index
      destination_type      = block_device.value.destination_type
      delete_on_termination = block_device.value.delete_on_termination
    }
  }

  lifecycle {
    # Image catalog rotation and out-of-band system disk expansion must not
    # replace an existing instance implicitly. An approved rebuild can still
    # be requested explicitly with -replace.
    ignore_changes = [
      image_id,
      block_device[0].uuid,
      block_device[0].volume_size,
    ]
  }

  dynamic "network" {
    for_each = var.network
    content {
      uuid           = network.value.uuid
      name           = network.value.name
      port           = network.value.port
      fixed_ip_v4    = network.value.fixed_ip_v4
      fixed_ip_v6    = network.value.fixed_ip_v6
      access_network = network.value.access_network
    }
  }

  dynamic "scheduler_hints" {
    for_each = var.scheduler_hints != null ? var.scheduler_hints : []
    content {
      group              = scheduler_hints.value.group
      different_host     = scheduler_hints.value.different_host
      same_host          = scheduler_hints.value.same_host
      query              = scheduler_hints.value.query
      target_cell        = scheduler_hints.value.target_cell
      build_near_host_ip = scheduler_hints.value.build_near_host_ip
      tenancy            = scheduler_hints.value.tenancy
      deh_id             = scheduler_hints.value.deh_id
    }
  }

  dynamic "timeouts" {
    for_each = var.timeouts != null ? [var.timeouts] : []
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      update = timeouts.value.update
    }
  }
}

# compute_keypair
resource "opentelekomcloud_compute_keypair_v2" "compute_instance_v2" {
  for_each = length(coalesce(var.compute_keypair, {})) == 1 ? { "this" = one(values(var.compute_keypair)) } : {}

  region      = var.region
  name        = each.value.name
  public_key  = each.value.public_key
  value_specs = each.value.value_specs
}

# evs_volume_v3
resource "opentelekomcloud_evs_volume_v3" "evs_volume_v3" {
  for_each = var.evs_volume != null ? var.evs_volume : {}

  availability_zone = each.value.availability_zone
  volume_type       = each.value.volume_type
  description       = each.value.description
  name              = each.value.name
  size              = each.value.size
  image_id          = each.value.image_id
  backup_id         = each.value.backup_id
  snapshot_id       = each.value.snapshot_id
  tags              = each.value.tags
  multiattach       = each.value.multiattach
  kms_id            = each.value.kms_id
  device_type       = each.value.device_type
  cascade           = each.value.cascade

  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : []
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
    }
  }
}

resource "opentelekomcloud_blockstorage_volume_v2" "this" {
  for_each = var.blockstorage_volume != null ? var.blockstorage_volume : {}

  region               = var.region
  size                 = each.value.size
  availability_zone    = each.value.availability_zone
  consistency_group_id = each.value.consistency_group_id
  description          = each.value.description
  image_id             = each.value.image_id
  metadata             = each.value.metadata
  tags                 = each.value.tags
  name                 = each.value.name
  snapshot_id          = each.value.snapshot_id
  source_replica       = each.value.source_replica
  source_vol_id        = each.value.source_vol_id
  volume_type          = each.value.volume_type
  device_type          = each.value.device_type
  cascade              = each.value.cascade

  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : []
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
    }
  }
}

# compute_volume_attach_v2
resource "opentelekomcloud_compute_volume_attach_v2" "evs_attach" {
  for_each = var.evs_volume != null ? var.evs_volume : {}

  region      = var.region
  device      = each.value.compute_volume_attach.device
  instance_id = opentelekomcloud_compute_instance_v2.compute_instance_v2.id
  volume_id   = opentelekomcloud_evs_volume_v3.evs_volume_v3[each.key].id

  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : []
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
    }
  }
}

# compute_volume_attach_v2
resource "opentelekomcloud_compute_volume_attach_v2" "blockstorage_attach" {
  for_each = var.blockstorage_volume != null ? var.blockstorage_volume : {}

  region      = var.region
  device      = each.value.compute_volume_attach.device
  instance_id = opentelekomcloud_compute_instance_v2.compute_instance_v2.id
  volume_id   = opentelekomcloud_blockstorage_volume_v2.this[each.key].id

  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : []
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
    }
  }
}
