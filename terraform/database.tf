
# Azure Database for PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = "psql-${var.prefix}-${var.project-code}"
  resource_group_name    = data.azurerm_resource_group.rg-lab.name
  location               = data.azurerm_resource_group.rg-lab.location
  version                = "18"
  delegated_subnet_id    = module.vnet.subnets["snet_postgres"].resource_id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres_dns.id
  administrator_login    = "devops_admin"
  administrator_password = data.azurerm_key_vault_secret.bd-pass.value

  # Especificar zone y HA evita conflictos al ejecutar nuevamente terraform apply con los recursos ya desplegados
  zone = var.primary-zone

  dynamic "high_availability" {
    for_each = var.prefix == "dev" ? [] : [1]
    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = var.standby_zone
    }
  }

  # Evita que Terraform revierta cambios de zona producidos por un failover manual o automático.
  lifecycle {
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone
    ]
  }

  storage_mb = var.prefix == "dev" ? 32768 : 131072
  sku_name   = var.prefix == "dev" ? "B_Standard_B1ms" : "GP_Standard_D2s_v3"

  public_network_access_enabled = false

  tags = {
    Environment = var.prefix
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres_dns_link]
}

# Base de datos
resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = "galeria_arte"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  collation = "en_US.utf8"
  charset   = "utf8"
}
