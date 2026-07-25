# terraform-oci-service-gateway

Terraform module that manages an [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
service gateway inside an existing VCN, giving private resources access to the Oracle
Services Network (Object Storage, Autonomous Database, and more) without traversing the
public internet.

## Usage

```hcl
# "All <region> Services In Oracle Services Network" covers the whole Oracle Services
# Network. Use "OCI <region> Object Storage" instead if you only want Object Storage.
data "oci_core_services" "all" {
  filter {
    name   = "name"
    values = ["^All .* Services In Oracle Services Network$"]
    regex  = true
  }
}

module "service_gateway" {
  source = "github.com/moveeeax/terraform-oci-service-gateway"

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "prod-sgw"

  # one() fails the plan if the filter matched zero or more than one service.
  service_ids = [one(data.oci_core_services.all.services).id]

  freeform_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Choosing the right service OCID

This is the one thing that is easy to get wrong and hard to notice. `oci_core_services`
returns several entries per region, and a service gateway built against the wrong one is
created successfully, reports `ACTIVE`, and quietly routes a different set of services
than you intended:

| Entry name                                         | Covers                          |
|----------------------------------------------------|---------------------------------|
| `All <region> Services In Oracle Services Network` | The full Oracle Services Network |
| `OCI <region> Object Storage`                      | Object Storage only              |

Two rules keep this honest:

- **Filter by name, then assert a single match.** `data.oci_core_services.all.services` is
  an API-ordered list; `services[0]` on an unfiltered or loosely filtered result picks an
  arbitrary entry. `one(...)` errors instead.
- **Pass service OCIDs, not CIDR labels.** Each element of the data source has both `id`
  (the `ocid1.service...` OCID you want) and `cidr_block`. The module rejects anything
  that is not a service OCID, so this fails at plan time rather than at apply.

### A note on `block_traffic`

`block_traffic = true` makes a service gateway drop all traffic while still existing and
reporting `ACTIVE` — the classic "Terraform applied cleanly, nothing works" state. The
`oci` provider exposes this attribute as read-only (computed), so this module cannot set
it and never turns it on. It is surfaced as the `block_traffic` output so callers can
assert on it if someone flips it out of band in the console.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| oci       | >= 5.0   |

## Inputs

| Name             | Description                                                        | Type           | Default | Required |
|------------------|--------------------------------------------------------------------|----------------|---------|:--------:|
| `compartment_id` | Compartment OCID (`ocid1.compartment...`, or the tenancy OCID).    | `string`       | n/a     |   yes    |
| `vcn_id`         | VCN OCID (`ocid1.vcn...`) the service gateway belongs to.          | `string`       | n/a     |   yes    |
| `display_name`   | Human-readable name for the service gateway.                       | `string`       | n/a     |   yes    |
| `service_ids`    | Service OCIDs (`ocid1.service...`); non-empty and duplicate-free.  | `list(string)` | n/a     |   yes    |
| `route_table_id` | Route table OCID (`ocid1.routetable...`). Null uses VCN default.   | `string`       | `null`  |    no    |
| `freeform_tags`  | Free-form tags applied to the service gateway.                     | `map(string)`  | `{}`    |    no    |
| `defined_tags`   | Defined tags applied to the gateway, keyed `namespace.key`.        | `map(string)`  | `{}`    |    no    |

## Outputs

| Name           | Description                             |
|----------------|-----------------------------------------|
| `id`           | OCID of the service gateway.            |
| `display_name` | Display name of the service gateway.    |
| `services`     | Services enabled on the service gateway.|
| `state`        | Lifecycle state of the service gateway. |
| `block_traffic`| Whether the gateway is dropping all traffic. |

## Tests

`terraform test` runs against a mocked `oci` provider, so it needs no credentials and no
network:

```sh
terraform init -backend=false
terraform test
```

The test files require Terraform >= 1.7 for `mock_provider`. The module itself still
supports >= 1.5.

## License

[MIT](LICENSE)
