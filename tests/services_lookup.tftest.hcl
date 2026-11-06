# Requires Terraform >= 1.7 for mock_provider and override_data. The module's own
# required_version stays at >= 1.5.
#
# Covers `services`, which resolves the service OCID inside the module from the
# oci_core_services data source. The mocked provider does not apply the name
# filter, so each run overrides the data source with what OCI would return for
# the filter the module sends.

mock_provider "oci" {}

variables {
  compartment_id = "ocid1.compartment.oc1..aaaaaaaaexamplecompartment"
  vcn_id         = "ocid1.vcn.oc1.iad.aaaaaaaaexamplevcn"
  display_name   = "test-sgw"
}

run "all_resolves_the_whole_services_network" {
  command = plan

  variables {
    services = "all"
  }

  override_data {
    target = data.oci_core_services.this[0]
    values = {
      services = [{
        id          = "ocid1.service.oc1.iad.aaaaaaaaallservicesnetwork"
        name        = "All IAD Services In Oracle Services Network"
        cidr_block  = "all-iad-services-in-oracle-services-network"
        description = "All IAD Services In Oracle Services Network"
      }]
    }
  }

  assert {
    condition     = one(data.oci_core_services.this[0].filter).values == tolist(["^All .* Services In Oracle Services Network$"])
    error_message = "services = \"all\" must filter oci_core_services by the All Services name pattern."
  }

  assert {
    condition = [
      for s in oci_core_service_gateway.this.services : s.service_id
    ] == ["ocid1.service.oc1.iad.aaaaaaaaallservicesnetwork"]
    error_message = "The resolved service OCID must be the only services block on the gateway."
  }

  assert {
    condition     = output.service_cidr_block == "all-iad-services-in-oracle-services-network"
    error_message = "service_cidr_block must expose the resolved service's CIDR label for route rules."
  }
}

run "objectstorage_resolves_object_storage_only" {
  command = plan

  variables {
    services = "objectstorage"
  }

  override_data {
    target = data.oci_core_services.this[0]
    values = {
      services = [{
        id          = "ocid1.service.oc1.iad.aaaaaaaaobjectstorage"
        name        = "OCI IAD Object Storage"
        cidr_block  = "oci-iad-objectstorage"
        description = "OCI IAD Object Storage"
      }]
    }
  }

  assert {
    condition     = one(data.oci_core_services.this[0].filter).values == tolist(["^OCI .* Object Storage$"])
    error_message = "services = \"objectstorage\" must filter oci_core_services by the Object Storage name pattern."
  }

  assert {
    condition = [
      for s in oci_core_service_gateway.this.services : s.service_id
    ] == ["ocid1.service.oc1.iad.aaaaaaaaobjectstorage"]
    error_message = "The resolved Object Storage OCID must reach the gateway."
  }
}

run "explicit_service_ids_skip_the_lookup" {
  command = plan

  variables {
    service_ids = ["ocid1.service.oc1.iad.aaaaaaaaallservicesnetwork"]
  }

  assert {
    condition     = length(data.oci_core_services.this) == 0
    error_message = "With service_ids the module must not read oci_core_services."
  }

  assert {
    condition     = output.service_cidr_block == null
    error_message = "service_cidr_block must be null when service_ids is used."
  }
}

run "rejects_no_match" {
  command = plan

  variables {
    services = "all"
  }

  override_data {
    target = data.oci_core_services.this[0]
    values = {
      services = []
    }
  }

  expect_failures = [data.oci_core_services.this]
}

run "rejects_more_than_one_match" {
  command = plan

  variables {
    services = "objectstorage"
  }

  override_data {
    target = data.oci_core_services.this[0]
    values = {
      services = [
        {
          id          = "ocid1.service.oc1.iad.aaaaaaaaobjectstorage1"
          name        = "OCI IAD Object Storage"
          cidr_block  = "oci-iad-objectstorage"
          description = "OCI IAD Object Storage"
        },
        {
          id          = "ocid1.service.oc1.iad.aaaaaaaaobjectstorage2"
          name        = "OCI IAD Object Storage Legacy Object Storage"
          cidr_block  = "oci-iad-objectstorage-legacy"
          description = "A second entry the regex also matches"
        },
      ]
    }
  }

  expect_failures = [data.oci_core_services.this]
}

run "rejects_unknown_services_value" {
  command = plan

  variables {
    services = "streaming"
  }

  expect_failures = [var.services]
}

run "rejects_both_services_and_service_ids" {
  command = plan

  variables {
    services    = "all"
    service_ids = ["ocid1.service.oc1.iad.aaaaaaaaallservicesnetwork"]
  }

  override_data {
    target = data.oci_core_services.this[0]
    values = {
      services = [{
        id          = "ocid1.service.oc1.iad.aaaaaaaaallservicesnetwork"
        name        = "All IAD Services In Oracle Services Network"
        cidr_block  = "all-iad-services-in-oracle-services-network"
        description = "All IAD Services In Oracle Services Network"
      }]
    }
  }

  expect_failures = [oci_core_service_gateway.this]
}

run "rejects_neither_services_nor_service_ids" {
  command = plan

  expect_failures = [oci_core_service_gateway.this]
}
