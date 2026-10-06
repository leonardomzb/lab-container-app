# 📌 Laboratorio DevOps: IaC & CI/CD en Azure

Este laboratorio tiene como objetivo principal diseñar e implementar un flujo de trabajo DevOps en Microsoft Azure, automatizando el ciclo de vida de la infraestructura y la aplicación, abarcando desde el aprovisionamiento declarativo hasta la entrega continua de contenedores.

## 🚀 Objetivos del Laboratorio

* **Infraestructura como Código (IaC):** Despliegue utilizando Terraform con gestión de estado remoto (*Remote Backend*).
* **Seguridad & Redes Zero-Trust:** Arquitectura aislada en VNet con Subredes Delegadas, Private Endpoints y gestión de identidades (*Managed Identities + RBAC*).
* **CI/CD con GitHub Actions:**
  * **Pipeline de Infraestructura:** Validación, planificación e implementación de cambios en Azure autenticado mediante OIDC (*OpenID Connect*).
  * **Pipeline de Aplicación:** Compilación de imágenes Docker, almacenamiento en Azure Container Registry (ACR) y actualización de revisiones *Zero-Downtime* en Azure Container Apps (ACA).

## 🏗️ Arquitectura

* **Frontend:** Nginx Proxy Inverso en Azure Container Apps (ACA) expuesto a Internet.
* **Backend:** REST API en Node.js en ACA (Ingress interno, accesible solo desde el Frontend).
* **Database:** PostgreSQL Flexible Server en red privada aislada (Private Endpoint / Subred Delegada).
* **Security & Auth:** Managed Identities para acceso a Azure Key Vault (secretos) y Azure Container Registry (imágenes), autenticación OIDC para GitHub Actions.

## 📂 Estructura del Repositorio

```text
.
├── .github/
│   └── workflows/
│       ├── dev-infra-deploy.yml     # Pipeline de IaC (Terraform)
│       ├── dev-app-cd.yml           # Pipeline de App (Build & Deploy)
│       └── dev-destroy.yml          # Destrucción manual de infra
├── app/
│   ├── backend/                 
│   └── frontend/                
└── terraform/                   
    ├── container-backend.tf
    ├── container-env.tf
    ├── container-frontend.tf
    ├── database.tf
    ├── dev-vars.tfvars
    ├── main.tf
    ├── network.tf
    └── variables.tf
```


## 📋 Prerrequisitos y Configuración Previa

Si deseas replicar este laboratorio, asegúrate de contar con los siguientes recursos y permisos configurados previamente en Azure:

### 1. Recursos Existentes en Azure
* **Resource Group** para el laboratorio.
* **Azure Container Registry (ACR)** para almacenar las imágenes.
* **Storage Account & Blob Container** para el *Remote Backend* de Terraform.
* **Azure Key Vault** con el secreto `db-password` para la base de datos PostgreSQL.

### 2. Secretos y Variables en GitHub (`Settings > Secrets and variables`)
* **Secrets:** `AZURE_CLIENT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_TENANT_ID` (credenciales OIDC).
* **Variables / Secrets:** `ACA_RESOURCE_GROUP`, `ACR_SERVER_NAME` y `ACR_NAME` en workflow `dev-app-cd.yml`.

### 3. Permisos de la Identidad Federada (Service Principal)
* **Resource Group:** `Contributor`.
* **Acure Container Registry:** `Contributor` y `User Access Administrator`.
* **Key Vault:** `Key Vault Secrets User` y `Key Vault Data Access Administrator`.
* **Storage Account:** `Reader` sobre la cuenta y `Storage Blob Data Contributor` sobre el contenedor del estado.

> ⚠️ **Nota:** Antes del primer despliegue, actualiza los nombres de tus recursos reales en `terraform/providers.tf` (para el backend de Terraform) y en `terraform/dev-vars.tfvars`.

> 💡 **Nota sobre los Triggers de CI/CD:** Para propósitos de este laboratorio, la ejecución de ambos workflows (`dev-infra-deploy.yml` y `dev-app-cd.yml`) se debe ejecutar mediante **`workflow_dispatch`** (desencadenamiento manual) en ese mismo orden.
