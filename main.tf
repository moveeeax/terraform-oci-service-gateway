locals {
  # Name patterns for the two service sets a service gateway can target. The
  # region appears in the middle of each name ("All IAD Services In Oracle
  # Services Network", "OCI IAD Object Storage"), so match around it.
  service_name_patterns = {
    all           = "^All .* Services In Oracle Services Network$"
    objectstorage = "^OCI .* Object Storage$"
  }

  resolve_services = var.services != null

  resolved_service = local.resolve_services ? one(data.oci_core_services.this[0].services) : null

  service_ids = local.resolve_services ? [local.resolved_service.id] : (var.service_ids != null ? var.service_ids : [])
}

data "oci_core_services" "this" {
  count = local.resolve_services ? 1 : 0

  filter {
    name   = "name"
    values = [local.service_name_patterns[var.services]]
    regex  = true
  }

  lifecycle {
    postcondition {
      condition     = length(self.services) == 1
      error_message = "Expected exactly one Oracle service matching \"${local.service_name_patterns[var.services]}\" in this region, found ${length(self.services)}: ${jsonencode([for s in self.services : s.name])}. Pass service_ids explicitly instead."
    }
  }
}

resource "oci_core_service_gateway" "this" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = var.display_name
  route_table_id = var.route_table_id

  dynamic "services" {
    for_each = local.service_ids
    content {
      service_id = services.value
    }
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    precondition {
      condition     = (var.services == null) != (var.service_ids == null)
      error_message = "Set exactly one of services (\"all\" or \"objectstorage\", resolved inside the module) or service_ids (explicit service OCIDs)."
    }
  }
}
