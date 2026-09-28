## 🌐 Additional Information

- The intended public repository name is `terraform-opentelekomcloud-compute-instance`, with module address `CloudAstro/compute-instance/opentelekomcloud` once published. The local folder name does not need to change.
- The complete `compute_instance_v2` output is sensitive because it includes instance configuration. Select specific attributes such as `.id` and `.name` in callers; use `nonsensitive()` only for attributes known not to contain secrets.
- For pre-created ports, put security groups on the ports. A port's fixed IP may need to be read from the port resource rather than the compute output.
- The full example generates its key pair through the OTC provider. The private key is stored in Terraform state and is not written to a local file or exported by the module. For regular SSH access, supply your own public key in `compute_keypair` instead.
- The full example has no public IP, NAT gateway or VPN. Access requires existing private connectivity; attached disks are not formatted or mounted automatically.

## 📚 Resources

- [Terraform Compute Instance Resource](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/compute_instance_v2)
- [Terraform EVS Volume Resource](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/evs_volume_v3)
- [Terraform Block Storage Volume Resource](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/blockstorage_volume_v2)
- [Contributing](CONTRIBUTING.md)

## ⚠️ Notes

- Image lifecycle behavior is retained: changes to the instance `image_id` and the first block device's `uuid` and `volume_size` are ignored after creation. Terraform does not reconcile these fields. Plan an explicit rebuild or a separate supported disk resize when needed.
- These lifecycle exceptions do not cover `image_name`, other disks or `user_data`. Changes to those inputs can replace the instance; review the plan.
- Each explicit block-device UUID now takes precedence over the module image. Previously, image-backed disks silently reused the module image. Review plans when upgrading consumers that supplied different disk UUIDs.
- `guest_format` and Block Storage v2 creation/deletion timeouts are now forwarded instead of ignored.
- The unused `block_device.os_disk`, `network.mac` and attachment `instance_id`/`volume_id` fields have been removed from the declared inputs. Device ordering and boot_index select the boot disk; the provider assigns MACs, and the module derives attachment IDs. Terraform can discard extra object attributes during conversion, so remove these old fields from callers.
- `compute_keypair` accepts at most one entry. Its existing `["this"]` resource address is preserved regardless of the input map key. Other resource addresses are unchanged; no migration blocks are added.
- Use a provider alias to select a different region consistently. Image lookup and EVS v3 volumes use the provider region even when the optional `region` override is set elsewhere.
- Sensitive marking hides values in normal output; passwords, user data and provider-generated private keys can still be stored in Terraform state. Protect the state backend and avoid embedding secrets in boot configuration.
- Generate this README with `terraform-docs .`; edit `_header.md`, `_footer.md` and Terraform descriptions. GitHub workflows assume the module is the root of a standalone repository.
- Release Please reads the configuration and manifest, with initial version `1.0.0`. No release is published by this preparation.

## 🧾 License

[Apache License 2.0](LICENSE), following the CloudAstro public module template.
