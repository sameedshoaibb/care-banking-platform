resource "azurerm_log_analytics_workspace" "log" {
  name                = "${var.prefix}-log-analytics"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "app_insights" {
  name                = "${var.prefix}-app-insights"
  location            = var.location
  resource_group_name = var.rg_name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.log.id
}

resource "azurerm_monitor_diagnostic_setting" "vm_diagnostic" {
  name                       = "${var.prefix}-vm-diagnostic"
  target_resource_id         = var.vm_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log.id

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_action_group" "alerts" {
  name                = "${var.prefix}-action-group"
  resource_group_name = var.rg_name
  short_name          = "alertgrp"

  email_receiver {
    name          = "DevOpsTeam"
    email_address = var.alert_email
  }
}

resource "azurerm_monitor_metric_alert" "high_cpu" {
  name                = "${var.prefix}-cpu-alert"
  resource_group_name = var.rg_name
  scopes              = [var.vm_id]
  description         = "Alert when CPU usage > 80%"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.alerts.id
  }
}
