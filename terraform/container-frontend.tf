
# Identidad para ACA frontend
resource "azurerm_user_assigned_identity" "frontend_identity" {
  name                = "id-frontend-${var.prefix}-${var.project-code}"
  location            = data.azurerm_resource_group.rg-lab.location
  resource_group_name = data.azurerm_resource_group.rg-lab.name

  tags = {
    Environment = var.prefix
  }
}

# 2.Rol AcrPull A LA IDENTIDAD (Antes de crear la Container App)
resource "azurerm_role_assignment" "acr_pull_frontend" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.frontend_identity.principal_id
}

# ACA Frontend
resource "azurerm_container_app" "frontend" {
  name                         = "aca-frontend-${var.prefix}-${var.project-code}"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = data.azurerm_resource_group.rg-lab.name
  revision_mode                = "Single"

  # Managed Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.frontend_identity.id]
  }

  # Indica que la imagen no es publica 
  registry {
    server   = data.azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.frontend_identity.id
  }

  # Ingress Público
  ingress {
    external_enabled = true
    target_port      = 8080
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    min_replicas = 1

    container {
      name   = "frontend-nginx"
      image  = var.frontend_image # Uso de imagen Placeholder
      cpu    = 0.25
      memory = "0.5Gi"

      # URL interna del Backend
      env {
        name  = "BACKEND_URL"
        value = "https://${azurerm_container_app.backend.ingress[0].fqdn}"
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

  depends_on = [azurerm_role_assignment.acr_pull_frontend]
}