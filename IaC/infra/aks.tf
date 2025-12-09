resource "azurerm_kubernetes_cluster" "demo" {
  name                = "${var.base_name}-aks"
  location            = var.region
  resource_group_name = azurerm_resource_group.demo.name
  dns_prefix          = "${var.base_name}-aks"
  kubernetes_version  = "1.33"

  private_cluster_enabled = false

  default_node_pool {
    name                 = "system"
    vm_size              = "Standard_D2alds_v6"
    auto_scaling_enabled = true
    min_count            = 2
    max_count            = 4
    vnet_subnet_id       = azurerm_subnet.aks.id

    os_sku = "AzureLinux"

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"

    service_cidr   = var.aks_service_cidr
    dns_service_ip = var.aks_dns_service_ip
    pod_cidr       = var.pod_cidr

    load_balancer_sku = "standard"

    ip_versions = ["IPv4"]

    load_balancer_profile {
      managed_outbound_ip_count = 1
    }
  }

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  image_cleaner_enabled        = true
  image_cleaner_interval_hours = 48

  lifecycle {
    ignore_changes = [
      network_profile[0].advanced_networking,
      microsoft_defender
    ]
  }

  depends_on = [
    azurerm_subnet.aks
  ]
}

# User node pool for workloads
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.demo.id
  vm_size               = "Standard_D2alds_v6"
  auto_scaling_enabled  = true
  min_count             = 2
  max_count             = 4
  vnet_subnet_id        = azurerm_subnet.aks.id

  os_sku = "AzureLinux"

  # Node labels for workload scheduling
  node_labels = {
    "workload" = "user"
  }

  upgrade_settings {
    drain_timeout_in_minutes      = 0
    max_surge                     = "10%"
    node_soak_duration_in_minutes = 0
  }

  depends_on = [azurerm_kubernetes_cluster.demo]
}

# ACR integration - Role assignment
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.demo.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.demo.id
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_kubernetes_cluster.demo,
    azurerm_container_registry.demo
  ]
}
