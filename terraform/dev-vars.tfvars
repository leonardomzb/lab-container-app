# Prefix y codigo para crear el nombre de recursos EJ: vnet-dev-terra-ansible
prefix       = "dev"
project-code = "galeria-arte"

# Nombre de grupo de recursos para laboratorio en Azure
rg-name = "rg-galeria-arte"

# Zonas de despliegue
primary-zone = "1"
standby_zone = "2"

# Grupo de recursos de Azure Key vault 
rg-kv-name = "rg-key-vault"
# Azure Key vault
kv = "kv-learn-labs"
# Secreto pass bd
bd-pass = "db-password"


# ACR con imagenes
# Grupo de recursos de ACR
rg-acr-name = "rg-acr-galeria"
# Nombre de ACR
acr = "acrgaleria"