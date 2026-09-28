data "opentelekomcloud_images_image_v2" "image" {
  for_each = var.image_reference != null ? { "this" = var.image_reference } : {}

  name_regex  = each.value.name_regex
  most_recent = each.value.most_recent
  visibility  = each.value.visibility
}
