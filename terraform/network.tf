
# VNET Y SUBNET
module "vnet" {

  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.22.2"

  name = "vnet-${var.prefix}-${var.project-code}"

  location  = data.azurerm_resource_group.rg-lab.location
  parent_id = data.azurerm_resource_group.rg-lab.id

  address_space = ["10.0.0.0/16"]

  subnets = {
    "snet_container_apps" = {
      name             = "snet_container_apps"
      address_prefixes = ["10.0.1.0/24"]
      delegations = [{
        name = "delegation-container-apps"
        service_delegation = {
          name = "Microsoft.App/environments"
        }
      }]
    },
    "snet_postgres" = {
      name             = "snet_postgres"
      address_prefixes = ["10.0.2.0/24"]
      delegations = [{
        name = "delegation-postgres"
        service_delegation = {
          name = "Microsoft.DBforPostgreSQL/flexibleServers"
        }
      }]
    }
  }

  tags = {
    Environment = var.prefix
  }
}

# ZONA DNS PRIVADA
resource "azurerm_private_dns_zone" "postgres_dns" {
  name                = "galeria-arte.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.rg-lab.name

  tags = {
    Environment = var.prefix
  }
}

# 6. Enlace Private DNS Zone a VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgres_dns_link" {
  name                  = "link-${var.prefix}-${var.project-code}"
  resource_group_name   = data.azurerm_resource_group.rg-lab.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name
  virtual_network_id    = module.vnet.resource_id

  tags = {
    Environment = var.prefix
  }
}