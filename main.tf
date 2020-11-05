terraform {
  required_version = ">= 0.12.0"
}

provider azurerm {
  version = "~> 2.34.0"
  features {}
}

locals {

  rhc = { for h in var.hybrid_connections : h.name => h }

  diag_namespace_logs = [
    "HybridConnectionsEvent",
  ]

  diag_namespace_metrics = [
    "AllMetrics",
  ]

  diag_resource_list = var.diagnostics != null ? split("/", var.diagnostics.destination) : []
  parsed_diag = var.diagnostics != null ? {
    log_analytics_id   = contains(local.diag_resource_list, "microsoft.operationalinsights") ? var.diagnostics.destination : null
    storage_account_id = contains(local.diag_resource_list, "Microsoft.Storage") ? var.diagnostics.destination : null
    event_hub_auth_id  = contains(local.diag_resource_list, "Microsoft.EventHub") ? var.diagnostics.destination : null
    metric             = contains(var.diagnostics.metrics, "all") ? local.diag_namespace_metrics : var.diagnostics.metrics
    log                = contains(var.diagnostics.logs, "all") ? local.diag_namespace_logs : var.diagnostics.logs
    } : {
    log_analytics_id   = null
    storage_account_id = null
    event_hub_auth_id  = null
    metric             = []
    log                = []
  }
}

resource "azurerm_resource_group" "arhc" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

resource "azurerm_relay_namespace" "arhc" {
  name                = "${var.name}-rhcn"
  location            = azurerm_resource_group.arhc.location
  resource_group_name = azurerm_resource_group.arhc.name

  sku_name = "Standard"

  tags = var.tags
}



resource "azurerm_relay_hybrid_connection" "arhc" {
  for_each = local.rhc

  name                          = each.key
  resource_group_name           = azurerm_resource_group.arhc.name
  relay_namespace_name          = azurerm_relay_namespace.arhc.name
  requires_client_authorization = true
  user_metadata                 = each.value.user_metadata
}

resource "azurerm_monitor_diagnostic_setting" "namespace" {
  count                          = var.diagnostics != null ? 1 : 0
  name                           = "${var.name}-ns-diag"
  target_resource_id             = azurerm_relay_namespace.arhc.id
  log_analytics_workspace_id     = local.parsed_diag.log_analytics_id
  eventhub_authorization_rule_id = local.parsed_diag.event_hub_auth_id
  eventhub_name                  = local.parsed_diag.event_hub_auth_id != null ? var.diagnostics.eventhub_name : null
  storage_account_id             = local.parsed_diag.storage_account_id

  dynamic "log" {
    for_each = local.parsed_diag.log
    content {
      category = log.value

      retention_policy {
        enabled = false
      }
    }
  }

  dynamic "metric" {
    for_each = local.parsed_diag.metric
    content {
      category = metric.value

      retention_policy {
        enabled = false
      }
    }
  }
}