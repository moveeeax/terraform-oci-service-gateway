# Requires Terraform >= 1.7 for mock_provider. The module's own required_version stays
# at >= 1.5; only running the test suite needs the newer CLI.
#
# Runs entirely against a mocked provider: no OCI credentials, no network.

mock_provider "oci" {}

variables {
  compartment_id = "ocid1.compartment.oc1..aaaaaaaaexamplecompartment"
  vcn_id         = "ocid1.vcn.oc1.iad.aaaaaaaaexamplevcn"
  display_name   = "test-sgw"
  service_ids    = ["ocid1.service.oc1.iad.aaaaaaaaallservicesnetwork"]
}

run "wires_service_ids_into_services_blocks" {
  command = plan

  assert {
    condition = [
      for s in oci_core_service_gateway.this.services : s.service_id
      ] == [
      "ocid1.service.oc1.iad.aaaaaaaaallservicesnetwork"
    ]
    error_message = "The services block must carry exactly the service OCIDs passed in service_ids."
  }

  assert {
    condition     = oci_core_service_gateway.this.vcn_id == var.vcn_id
    error_message = "The gateway must be attached to the VCN given in vcn_id."
  }

  assert {
    condition     = oci_core_service_gateway.this.compartment_id == var.compartment_id
    error_message = "The gateway must be created in the compartment given in compartment_id."
  }
}

run "multiple_services_all_reach_the_gateway" {
  command = plan

  variables {
    service_ids = [
      "ocid1.service.oc1.iad.aaaaaaaaallservicesnetwork",
      "ocid1.service.oc1.iad.aaaaaaaaobjectstorage",
    ]
  }

  # Compared as a set of service_id: every OCID passed in must produce a services block,
  # with nothing dropped, added, or substituted. A dropped entry silently removes service
  # access. (length() of the block set itself is unknown at plan time because
  # service_name is provider-computed, so project to service_id first.)
  assert {
    condition = toset([
      for s in oci_core_service_gateway.this.services : s.service_id
      ]) == toset([
      "ocid1.service.oc1.iad.aaaaaaaaallservicesnetwork",
      "ocid1.service.oc1.iad.aaaaaaaaobjectstorage",
    ])
    error_message = "The services block must contain exactly the OCIDs passed in service_ids, with none dropped or substituted."
  }
}

run "route_table_defaults_to_null_so_the_vcn_default_is_used" {
  command = plan

  assert {
    condition     = var.route_table_id == null
    error_message = "route_table_id must default to null so the gateway falls back to the VCN default route table."
  }
}

run "route_table_is_associated_when_given" {
  command = plan

  variables {
    route_table_id = "ocid1.routetable.oc1.iad.aaaaaaaaexamplert"
  }

  assert {
    condition     = oci_core_service_gateway.this.route_table_id == "ocid1.routetable.oc1.iad.aaaaaaaaexamplert"
    error_message = "route_table_id must be passed through to the gateway; otherwise traffic is never routed to it."
  }
}

run "tags_are_passed_through" {
  command = plan

  variables {
    freeform_tags = { Environment = "test" }
    defined_tags  = { "Operations.CostCenter" = "42" }
  }

  assert {
    condition     = oci_core_service_gateway.this.freeform_tags["Environment"] == "test"
    error_message = "freeform_tags must reach the gateway."
  }

  assert {
    condition     = oci_core_service_gateway.this.defined_tags["Operations.CostCenter"] == "42"
    error_message = "defined_tags must reach the gateway."
  }
}

# --- input validation -------------------------------------------------------
# The provider enforces min_items = 1 on services and rejects malformed OCIDs only at
# apply time, against the real API. These checks move the failure to plan time.

run "rejects_empty_service_ids" {
  command = plan

  variables {
    service_ids = []
  }

  expect_failures = [var.service_ids]
}

run "rejects_non_service_ocid" {
  command = plan

  # A subnet OCID: plausible-looking, wrong resource type.
  variables {
    service_ids = ["ocid1.subnet.oc1.iad.aaaaaaaaexamplesubnet"]
  }

  expect_failures = [var.service_ids]
}

run "rejects_cidr_block_in_place_of_service_ocid" {
  command = plan

  # oci_core_services entries expose both `id` and `cidr_block`; grabbing the wrong
  # attribute is the easy mistake this guards against.
  variables {
    service_ids = ["all-iad-services-in-oracle-services-network"]
  }

  expect_failures = [var.service_ids]
}

run "rejects_duplicate_service_ids" {
  command = plan

  # services is a set, so a duplicate collapses: the caller thinks they enabled two
  # services and got one.
  variables {
    service_ids = [
      "ocid1.service.oc1.iad.aaaaaaaaobjectstorage",
      "ocid1.service.oc1.iad.aaaaaaaaobjectstorage",
    ]
  }

  expect_failures = [var.service_ids]
}

run "rejects_non_compartment_ocid" {
  command = plan

  variables {
    compartment_id = "ocid1.vcn.oc1.iad.aaaaaaaawrongtype"
  }

  expect_failures = [var.compartment_id]
}

run "accepts_tenancy_ocid_as_root_compartment" {
  command = plan

  variables {
    compartment_id = "ocid1.tenancy.oc1..aaaaaaaaexampletenancy"
  }

  assert {
    condition     = oci_core_service_gateway.this.compartment_id == "ocid1.tenancy.oc1..aaaaaaaaexampletenancy"
    error_message = "The tenancy OCID is a valid compartment_id for the root compartment and must not be rejected."
  }
}

run "rejects_non_vcn_ocid" {
  command = plan

  variables {
    vcn_id = "ocid1.subnet.oc1.iad.aaaaaaaawrongtype"
  }

  expect_failures = [var.vcn_id]
}

run "rejects_non_route_table_ocid" {
  command = plan

  variables {
    route_table_id = "ocid1.vcn.oc1.iad.aaaaaaaawrongtype"
  }

  expect_failures = [var.route_table_id]
}
