variable "prefix" {
  type        = string
  description = "Prefix para el entorno de desarrollo"
}

variable "project-code" {
  type        = string
  description = "Codigo del proyecto para nombres de recursos"
}

variable "rg-name" {
  type        = string
  description = "Nombre del grupo de recursos del proyecto"
}

variable "primary-zone" {
  type        = string
  default     = "1"
  description = "Zona principal para recursos"
}

variable "standby_zone" {
  type        = string
  default     = "2"
  description = "Zona común high_availability para recursos"
}

# KV
variable "rg-kv-name" {
  type        = string
  description = "Nombre del grupo de recursos de la KV"
}

variable "kv" {
  type        = string
  description = "Nombre de la KV"
}

variable "bd-pass" {
  type        = string
  description = "Secreto con password de Posgres"
}

# ACR
variable "rg-acr-name" {
  type        = string
  description = "Nombre de GR de ACR"
}

variable "acr" {
  type        = string
  description = "Nombre de ACR"
}

# Imágenes Placeholder para levantar infraestructura inicial sin app real
variable "backend_image" {
  type        = string
  description = "Imagen de contenedor para el Backend API"
  # Si no se especifica, usa un placeholder ligero
  default = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
}

variable "frontend_image" {
  type        = string
  description = "Imagen de contenedor para el Frontend Nginx"
  # Si no se especifica, usa un placeholder ligero
  default = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
}

