# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `services` input (`"all"` or `"objectstorage"`): the module reads
  `oci_core_services`, filters it by the "All <region> Services In Oracle Services
  Network" or "OCI <region> Object Storage" name pattern and fails the plan unless
  exactly one service matches, so callers no longer need their own data source.
- `service_cidr_block` output with the resolved service's CIDR label, for route
  rules with `destination_type = "SERVICE_CIDR_BLOCK"`.

### Changed

- `service_ids` is now optional (default `null`) and mutually exclusive with
  `services`; exactly one of the two must be set. Existing callers that pass
  `service_ids` are unaffected.

### Changed

- CI: bump actions to their current majors, pin tool versions, and restrict the
  workflow token to `contents: read`.
- CI: add Dependabot for GitHub Actions and the Terraform provider.
- Docs: pin the README usage `source` to a release tag; fix the LICENSE year.

## [1.0.0]

Initial release (`v0.1.0` points at the same commit).

[Unreleased]: https://github.com/moveeeax/terraform-oci-service-gateway/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/moveeeax/terraform-oci-service-gateway/releases/tag/v1.0.0
