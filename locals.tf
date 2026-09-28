locals {
  image_id = var.image_reference != null ? data.opentelekomcloud_images_image_v2.image["this"].id : var.image_id
  boot_from_volume = anytrue([
    for device in coalesce(var.block_device, []) :
    coalesce(device.boot_index, 0) == 0 && device.destination_type == "volume"
  ])
}
