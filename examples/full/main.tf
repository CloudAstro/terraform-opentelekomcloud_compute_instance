# Use the configured provider region for both compute and storage.
data "opentelekomcloud_compute_availability_zones_v2" "available" {
  state = "available"
}

module "vpc" {
  source  = "CloudAstro/vpc/opentelekomcloud"
  version = "1.1.1"

  name = "compute-example"
  cidr = "10.42.0.0/16"
}

module "subnet" {
  source  = "CloudAstro/vpc-subnet/opentelekomcloud"
  version = "1.1.1"

  name       = "compute-example"
  cidr       = "10.42.1.0/24"
  gateway_ip = "10.42.1.1"
  vpc_id     = module.vpc.vpc_v1.id
}

resource "opentelekomcloud_networking_secgroup_v2" "instance" {
  name        = "compute-example"
  description = "Private instance access"
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "ssh" {
  security_group_id = opentelekomcloud_networking_secgroup_v2.instance.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "10.42.1.0/24"
}

module "instance" {
  source = "../.."

  name                = "compute-full-example"
  description         = "Volume-backed instance with an attached data disk"
  flavor_name         = "s3.large.2"
  availability_zone   = data.opentelekomcloud_compute_availability_zones_v2.available.names[0]
  security_groups     = [opentelekomcloud_networking_secgroup_v2.instance.name]
  network             = [{ uuid = module.subnet.vpc_subnet.network_id }]
  power_state         = "active"
  stop_before_destroy = true
  metadata            = { purpose = "module-example" }
  tags                = { environment = "example", managed_by = "terraform" }

  # Illustrative image selection; image, flavor and zone availability vary by region.
  image_reference = {
    name_regex  = "^Standard_Ubuntu_22[.]04_amd64_uefi_latest$"
    most_recent = true
    visibility  = "public"
  }

  # Omitting public_key lets the provider generate an example key pair.
  # Its private key is stored in Terraform state; import your own public key for regular use.
  compute_keypair = {
    example = {
      name = "compute-full-example"
    }
  }

  block_device = [{
    source_type           = "image"
    destination_type      = "volume"
    boot_index            = 0
    volume_size           = 40
    volume_type           = "SSD"
    delete_on_termination = true
  }]

  evs_volume = {
    data = {
      name              = "compute-example-data"
      availability_zone = data.opentelekomcloud_compute_availability_zones_v2.available.names[0]
      volume_type       = "SSD"
      size              = 10
      tags              = { environment = "example" }
      timeouts          = { create = "10m", delete = "10m" }
    }
  }

  config_drive = true
  user_data    = <<-CLOUD_CONFIG
    #cloud-config
    write_files:
      - path: /etc/module-example
        content: Provisioned by Terraform
        permissions: '0644'
  CLOUD_CONFIG

  timeouts = {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}
