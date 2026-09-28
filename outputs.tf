output "compute_instance_v2" {
  value       = opentelekomcloud_compute_instance_v2.compute_instance_v2
  sensitive   = true
  description = <<DESCRIPTION
The complete instance resource, including its ID, name and network information.
Marked sensitive because it can contain admin_pass and user_data. Export only
individual non-secret attributes when a caller needs visible outputs.

Example output:
```hcl
output "instance_id" {
  value = nonsensitive(module.instance.compute_instance_v2.id)
}
```
DESCRIPTION
}
