output "id" {
  description = "OCID of the service gateway."
  value       = oci_core_service_gateway.this.id
}

output "display_name" {
  description = "Display name of the service gateway."
  value       = oci_core_service_gateway.this.display_name
}

output "services" {
  description = "Services enabled on the service gateway."
  value       = oci_core_service_gateway.this.services
}

output "state" {
  description = "Lifecycle state of the service gateway."
  value       = oci_core_service_gateway.this.state
}

# block_traffic is read-only in the oci provider (computed, not settable), so the module
# cannot manage it. It is surfaced here because a gateway with block_traffic = true is
# ACTIVE and looks healthy while dropping every packet -- worth asserting on in callers.
output "block_traffic" {
  description = "Whether the gateway is blocking all traffic. True means the gateway exists but passes nothing."
  value       = oci_core_service_gateway.this.block_traffic
}
