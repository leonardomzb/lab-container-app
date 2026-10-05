# Identidad para ACA backend
resource "azurerm_user_assigned_identity" "backend_identity" {
  name                = "id-backend-${var.prefix}-${var.project-code}"
  location            = data.azurerm_resource_group.rg-lab.location
  resource_group_name = data.azurerm_resource_group.rg-lab.name

  tags = {
    Environment = var.prefix
  }
}

# Asignación del rol "Key Vault Secrets User" a la Identidad sobre la Key Vault
resource "azurerm_role_assignment" "kv_secret_user" {
  scope                = data.azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.backend_identity.principal_id
}

# Asignacion de rol "AcrPull" sobre ACR
resource "azurerm_role_assignment" "acr-pull" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.backend_identity.principal_id
}

# Para evitar errores de dependencias al desplegar
resource "time_sleep" "wait_20_seconds_for_azure_replication" {
  depends_on = [
    azurerm_user_assigned_identity.backend_identity,
    azurerm_role_assignment.kv_secret_user,
    azurerm_role_assignment.acr-pull
  ]

  create_duration = "20s"
}

# ACA Backend
resource "azurerm_container_app" "backend" {
  name                         = "aca-backend-${var.prefix}-${var.project-code}"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = data.azurerm_resource_group.rg-lab.name
  revision_mode                = "Single"

  # Managed Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.backend_identity.id]
  }

  # Indica que la imagen no es publica 
  registry {
    server   = data.azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.backend_identity.id
  }

  # Crea el secreto vinculado a la identidad del ACA, el valor dependerá del secreto en KeyVault
  secret {
    name                = "db-password-secret"
    key_vault_secret_id = data.azurerm_key_vault_secret.bd-pass.versionless_id # versionless_id para actualización del valor automático
    identity            = azurerm_user_assigned_identity.backend_identity.id
  }

  # Ingress Interno
  ingress {
    external_enabled = false
    target_port      = 3000
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    min_replicas = 1

    container {
      name   = "backend-api"
      image  = var.backend_image # Uso de imagen Placeholder
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.postgres.fqdn
      }
      env {
        name  = "DB_USER"
        value = azurerm_postgresql_flexible_server.postgres.administrator_login
      }
      env {
        name  = "DB_NAME"
        value = azurerm_postgresql_flexible_server_database.db.name
      }
      # Se vincula el valor de la Variable con el valor del secreto vinculado a la identidad
      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password-secret"
      }
      # Se sobrescribe el valor de la variable a "true". Necesario para el servidor PostgreSQL
      env {
        name  = "DB_SSL"
        value = "true"
      }
    }
  }

  # Evita que terraform sobrescriba la imagen de la app real en caso de cambiar algo en la infraestructura y volver a ejecutar terraform apply
  lifecycle {
    ignore_changes = [
      template[0].container[0].image
    ]
  }

  tags = {
    Environment = var.prefix
  }

  # Asegura que el permiso RBAC exista ANTES de que ACA intente conectarse al Key Vault
  depends_on = [time_sleep.wait_20_seconds_for_azure_replication]
}

