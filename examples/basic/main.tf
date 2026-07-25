provider "oci" {}

# Look up the "All <region> Services In Oracle Services Network" entry, which covers the
# whole Oracle Services Network. Use "OCI <region> Object Storage" instead if you only
# want Object Storage -- the two are different service sets and the gateway will happily
# be created with either.
data "oci_core_services" "all" {
  filter {
    name   = "name"
    values = ["^All .* Services In Oracle Services Network$"]
    regex  = true
  }
}

module "service_gateway" {
  source = "../.."

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "example-sgw"
  # one() errors if the filter matched anything other than exactly one service, rather
  # than silently picking whatever the API happened to return first.
  service_ids = [one(data.oci_core_services.all.services).id]

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
