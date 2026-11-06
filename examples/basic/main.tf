provider "oci" {}

module "service_gateway" {
  source = "../.."

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "example-sgw"

  # "all" routes to the whole Oracle Services Network; "objectstorage" to Object
  # Storage only. The module looks the service up in the current region and fails
  # the plan unless exactly one entry matches.
  services = "all"

  freeform_tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

variable "compartment_id" {
  description = "Compartment OCID to deploy the example service gateway into."
  type        = string
}

variable "vcn_id" {
  description = "OCID of the VCN to attach the example service gateway to."
  type        = string
}

output "service_gateway_id" {
  value = module.service_gateway.id
}

# Destination for a route rule with destination_type = "SERVICE_CIDR_BLOCK".
output "service_cidr_block" {
  value = module.service_gateway.service_cidr_block
}
