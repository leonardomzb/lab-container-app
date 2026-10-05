# Grupo de recursos del laboratorio
data "azurerm_resource_group" "rg-lab" {
  name = var.rg-name
}

# Grupo de recursos de la key vault
data "azurerm_resource_group" "rg-kv-name" {
  name = var.rg-kv-name
}

# Key Vault
data "azurerm_key_vault" "kv" {
  name                = var.kv
  resource_group_name = data.azurerm_resource_group.rg-kv-name.name
}

# Secreto con password de PostgreSQL
data "azurerm_key_vault_secret" "bd-pass" {
  name         = var.bd-pass
  key_vault_id = data.azurerm_key_vault.kv.id
}

# ACR con imagenes
data "azurerm_container_registry" "acr" {
  name                = var.acr
  resource_group_name = var.rg-acr-name
}
