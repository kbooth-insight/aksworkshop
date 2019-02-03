output "analytics_primary_shared_key" {
    value = "${azurerm_log_analytics_workspace.log_workspace.primary_shared_key}"
}

output "secondary_primary_shared_key" {
    value = "${azurerm_log_analytics_workspace.log_workspace.secondary_shared_key}"
}