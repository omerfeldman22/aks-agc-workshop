# Data source to get AKS cluster credentials
data "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.base_name}-aks"
  resource_group_name = "${var.base_name}-rg"
}

# Data source to get ACR details
data "azurerm_container_registry" "acr" {
  name                = "${var.base_name}acr"
  resource_group_name = "${var.base_name}-rg"
}

# Data source to get resource group
data "azurerm_resource_group" "rg" {
  name = "${var.base_name}-rg"
}

# Data source to get DNS zone
data "azurerm_dns_zone" "dns" {
  name                = "${var.base_name}-${var.domain_suffix}.com"
  resource_group_name = "${var.base_name}-rg"
}

# Data source to get VNet
data "azurerm_virtual_network" "vnet" {
  name                = "${var.base_name}-vnet"
  resource_group_name = "${var.base_name}-rg"
}

# Data source to get current client config
data "azurerm_client_config" "current" {}
