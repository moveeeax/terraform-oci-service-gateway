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

variable "service_ids" {
  description = <<-EOT
    Service OCIDs the gateway routes to, taken from the `oci_core_services` data source.
    Each entry must be a service OCID ("ocid1.service...") -- not a CIDR block, a service
    name, or any other OCID type. Picking the wrong entry silently grants access to the
    wrong set of services, so filter the data source by name and assert a single match
    (see the README) instead of indexing into an unfiltered result.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.service_ids) > 0
    error_message = "At least one service OCID must be provided."
  }

  validation {
    condition     = alltrue([for s in var.service_ids : can(regex("^ocid1\\.service\\.", s))])
    error_message = "Every entry in service_ids must be a service OCID starting with \"ocid1.service.\". A CIDR block, service name, or other OCID type will not work."
  }

  validation {
    condition     = length(distinct(var.service_ids)) == length(var.service_ids)
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
