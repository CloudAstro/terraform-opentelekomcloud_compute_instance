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

module "instance" {
  source = "../.."

  name        = "compute-example"
  flavor_name = "s3.large.2"
  network     = [{ uuid = module.subnet.vpc_subnet.network_id }]

  # Illustrative public image selection; availability depends on the region.
  image_reference = {
    name_regex  = "^Standard_Ubuntu_22[.]04_amd64_uefi_latest$"
    most_recent = true
    visibility  = "public"
  }
}
