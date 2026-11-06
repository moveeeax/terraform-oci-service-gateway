variable "compartment_id" {
  description = "OCID of the compartment in which to create the service gateway. The tenancy OCID is accepted for the root compartment."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment OCID (\"ocid1.compartment...\") or the tenancy OCID for the root compartment."
  }
}

variable "vcn_id" {
  description = "OCID of the VCN the service gateway belongs to."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.vcn\\.", var.vcn_id))
    error_message = "vcn_id must be a VCN OCID starting with \"ocid1.vcn.\"."
  }
}

variable "display_name" {
  description = "Human-readable name for the service gateway."
  type        = string
}

variable "services" {
  description = <<-EOT
    Which Oracle Services Network set the gateway routes to, resolved inside the
    module from the `oci_core_services` data source: "all" picks "All <region>
    Services In Oracle Services Network", "objectstorage" picks "OCI <region>
    Object Storage". The plan fails unless exactly one service matches. Set this
    or `service_ids`, not both.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.services == null ? true : contains(["all", "objectstorage"], var.services)
    error_message = "services must be \"all\" (the whole Oracle Services Network) or \"objectstorage\" (Object Storage only)."
  }
}

variable "service_ids" {
  description = <<-EOT
    Explicit service OCIDs the gateway routes to, taken from the `oci_core_services`
    data source. Each entry must be a service OCID ("ocid1.service...") -- not a CIDR
    block, a service name, or any other OCID type. Prefer `services`, which does the
    lookup inside the module; use this when you need an OCID that `services` does not
    cover. Set this or `services`, not both.
  EOT
  type        = list(string)
  default     = null

  validation {
    condition     = var.service_ids == null ? true : length(var.service_ids) > 0
    error_message = "service_ids must be null or contain at least one service OCID."
  }

  validation {
    condition     = var.service_ids == null ? true : alltrue([for s in var.service_ids : can(regex("^ocid1\\.service\\.", s))])
    error_message = "Every entry in service_ids must be a service OCID starting with \"ocid1.service.\". A CIDR block, service name, or other OCID type will not work."
  }

  validation {
    condition     = var.service_ids == null ? true : length(distinct(var.service_ids)) == length(var.service_ids)
    error_message = "service_ids must not contain duplicates. The gateway's services are a set, so a repeated OCID is silently collapsed instead of adding a second service."
  }
}

variable "route_table_id" {
  description = "OCID of the route table the gateway uses. Null uses the VCN default."
  type        = string
  default     = null

  validation {
    condition     = var.route_table_id == null ? true : can(regex("^ocid1\\.routetable\\.", var.route_table_id))
    error_message = "route_table_id must be null or a route table OCID starting with \"ocid1.routetable.\"."
  }
}

variable "freeform_tags" {
  description = "Free-form tags applied to the service gateway."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags applied to the service gateway, keyed as \"namespace.key\"."
  type        = map(string)
  default     = {}
}
