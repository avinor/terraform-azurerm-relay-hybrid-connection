output "id" {
  description = "The Azure Relay Namespace ID"
  value       = azurerm_relay_namespace.arhc.id
}

output "name" {
  description = "Name of the Azure Relay Namespace created."
  value       = azurerm_relay_namespace.arhc.name
}

output "relay_hybrid_connections_ids" {
  description = "Map of relay hybrid connections and their ids."
  value       = { for k, v in azurerm_relay_hybrid_connection.arhc : k => v.id }
}