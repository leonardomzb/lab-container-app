
# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  # Solo se creará si el prefijo es distinto a "dev"
  count = var.prefix != "dev" ? 1 : 0

  name                = "law-${var.prefix}-${var.project-code}"
  location            = data.azurerm_resource_group.rg-lab.location
  resource_group_name = data.azurerm_resource_group.rg-lab.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.prefix
  }
}

resource "azurerm_container_app_environment" "env" {
  name                       = "cae-${var.prefix}-${var.project-code}"
  location                   = data.azurerm_resource_group.rg-lab.location
  resource_group_name        = data.azurerm_resource_group.rg-lab.name
  log_analytics_workspace_id = one(azurerm_log_analytics_workspace.law[*].id)

  #'dev' solo stream, de lo contrario usa "log-analytics"
  logs_destination = var.prefix == "dev" ? null : "log-analytics"

  # Integración a la subred delegada
  infrastructure_subnet_id = module.vnet.subnets["snet_container_apps"].resource_id

  # Ingress. Para mantener el frontend público dentro de la infraestructura.
  internal_load_balancer_enabled = false

  tags = {
    Environment = var.prefix
  }
}