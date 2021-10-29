terraform {
  required_version = ">= 0.13"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.51.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {

  rhc = { for h in var.hybrid_connections : h.name => h }

  keys = { for tk in flatten([for h in var.hybrid_connections :
    [for k in h.keys : {
      hc  = h.name
      key = k
  }]]) : format("%s.%s", tk.hc, tk.key.name) => tk }

  diag_namespace_logs = [
    "HybridConnectionsEvent",
  ]

  diag_namespace_metrics = [
    "AllMetrics",
  ]

  diag_resource_list = var.diagnostics != null ? split("/", var.diagnostics.destination) : []
  parsed_diag = var.diagnostics != null ? {
    log_analytics_id   = contains(local.diag_resource_list, "Microsoft.OperationalInsights") ? var.diagnostics.destination : null
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

data "azurerm_client_config" "current" {}

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

# Use az relay command because of https://github.com/terraform-providers/terraform-provider-azurerm/issues/7218
resource "null_resource" "authorization_rules" {
  for_each = local.keys

  provisioner "local-exec" {
    command = "az relay hyco authorization-rule create --subscription ${data.azurerm_client_config.current.subscription_id} --resource-group ${azurerm_resource_group.arhc.name} --namespace-name ${azurerm_relay_namespace.arhc.name} --hybrid-connection-name ${each.value.hc} --name ${each.value.key.name} --rights ${each.value.key.rights}"
  }

  depends_on = [azurerm_relay_hybrid_connection.arhc]
}


data "azurerm_monitor_diagnostic_categories" "default" {
  resource_id = azurerm_relay_namespace.arhc.id
}

resource "azurerm_monitor_diagnostic_setting" "namespace" {
  count                          = var.diagnostics != null ? 1 : 0
  name                           = "${var.name}-ns-diag"
  target_resource_id             = azurerm_relay_namespace.arhc.id
  log_analytics_workspace_id     = local.parsed_diag.log_analytics_id
  eventhub_authorization_rule_id = local.parsed_diag.event_hub_auth_id
  eventhub_name                  = local.parsed_diag.event_hub_auth_id != null ? var.diagnostics.eventhub_name : null
  storage_account_id             = local.parsed_diag.storage_account_id

  # For each available log category, check if it should be enabled and set enabled = true if it should.
  # All other categories are created with enabled = false to prevent TF from showing changes happening with each plan/apply.
  # Ref: https://github.com/terraform-providers/terraform-provider-azurerm/issues/7235
  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.default.logs
    content {
      category = log.value
      enabled  = contains(local.parsed_diag.log, log.value)

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }

  # For each available metric category, check if it should be enabled and set enabled = true if it should.
  # All other categories are created with enabled = false to prevent TF from showing changes happening with each plan/apply.
  # Ref: https://github.com/terraform-providers/terraform-provider-azurerm/issues/7235
  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.default.metrics
    content {
      category = metric.value
      enabled  = contains(local.parsed_diag.metric, metric.value)

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }
}
