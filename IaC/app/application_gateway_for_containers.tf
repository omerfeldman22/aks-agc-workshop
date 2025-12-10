# ========================================
# Application Gateway for Containers (AGC)
# ========================================

# Create managed identity for ALB Controller
resource "azurerm_user_assigned_identity" "alb_controller" {
  name                = "azure-alb-identity"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
}

# Federated identity credential for ALB Controller with AKS OIDC
resource "azurerm_federated_identity_credential" "alb_controller" {
  name                = "azure-alb-identity"
  resource_group_name = data.azurerm_resource_group.rg.name
  parent_id           = azurerm_user_assigned_identity.alb_controller.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = data.azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject             = "system:serviceaccount:azure-alb-system:alb-controller-sa"
}

# Assign Reader role to ALB Controller managed identity on AKS managed resource group
resource "azurerm_role_assignment" "alb_controller_reader" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${data.azurerm_kubernetes_cluster.aks.node_resource_group}"
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.alb_controller.principal_id
}

# Assign AppGw for Containers Configuration Manager role to ALB Controller on AKS managed resource group
resource "azurerm_role_assignment" "alb_controller_appgw_config_manager" {
  scope              = "/subscriptions/${var.subscription_id}/resourceGroups/${data.azurerm_kubernetes_cluster.aks.node_resource_group}"
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/fbc52c3f-28ad-4303-a892-8a056630b8f1"
  principal_id       = azurerm_user_assigned_identity.alb_controller.principal_id
}

# Get the AGC subnet from infra
data "azurerm_subnet" "agc" {
  name                 = "agc-subnet"
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

# Assign Network Contributor role to ALB Controller on AGC subnet
resource "azurerm_role_assignment" "alb_controller_network_contributor" {
  scope                = data.azurerm_subnet.agc.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.alb_controller.principal_id
}

# Assign Contributor role to ALB Controller on the resource group for WAF policies
# This allows the controller to join/use any WAF policy in the resource group
resource "azurerm_role_assignment" "alb_controller_waf_contributor" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.alb_controller.principal_id
}

# Install ALB Controller using Helm
resource "helm_release" "alb_controller" {
  name             = "alb-controller"
  repository       = "oci://mcr.microsoft.com/application-lb/charts"
  chart            = "alb-controller"
  version          = "1.8.12"
  namespace        = "default"
  create_namespace = false

  set {
    name  = "albController.namespace"
    value = "azure-alb-system"
  }

  set {
    name  = "albController.podIdentity.clientID"
    value = azurerm_user_assigned_identity.alb_controller.client_id
  }

  depends_on = [
    azurerm_federated_identity_credential.alb_controller,
    azurerm_role_assignment.alb_controller_reader,
    azurerm_role_assignment.alb_controller_appgw_config_manager,
    azurerm_role_assignment.alb_controller_network_contributor,
    azurerm_role_assignment.alb_controller_waf_contributor
  ]
}

# Namespace for ALB infrastructure
resource "kubernetes_namespace_v1" "alb_networking" {
  metadata {
    name = "alb-networking"
  }

  depends_on = [helm_release.alb_controller]
}

# Wait for CRD to be installed
resource "time_sleep" "wait_for_alb_crd" {
  create_duration = "60s"

  depends_on = [helm_release.alb_controller]
}

# ApplicationLoadBalancer custom resource
resource "kubectl_manifest" "application_load_balancer" {
  yaml_body = <<-YAML
    apiVersion: alb.networking.azure.io/v1
    kind: ApplicationLoadBalancer
    metadata:
      name: alb-networking
      namespace: ${kubernetes_namespace_v1.alb_networking.metadata[0].name}
      annotations:
        alb.networking.azure.io/alb-pod-ip-range: "10.244.240.0/24"
    spec:
      associations:
      - ${data.azurerm_subnet.agc.id}
  YAML

  depends_on = [
    kubernetes_namespace_v1.alb_networking,
    time_sleep.wait_for_alb_crd
  ]
}
