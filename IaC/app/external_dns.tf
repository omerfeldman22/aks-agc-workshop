# ========================================
# External DNS Resources
# ========================================

# Service Principal for External DNS
resource "azuread_application" "external_dns" {
  display_name = "${var.base_name}-external-dns-app"
}

resource "azuread_service_principal" "external_dns" {
  client_id = azuread_application.external_dns.client_id
}

resource "azuread_application_password" "external_dns" {
  application_id = azuread_application.external_dns.id
  display_name   = "external-dns-secret"
}

# Role assignment for External DNS to manage DNS zones
resource "azurerm_role_assignment" "external_dns_dns_contributor" {
  scope                = data.azurerm_dns_zone.dns.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azuread_service_principal.external_dns.object_id
}


# Namespace for External DNS
resource "kubernetes_namespace_v1" "external_dns" {
  metadata {
    name = "external-dns"
    labels = {
      name = "external-dns"
    }
  }
}

# Secret for Azure DNS authentication
resource "kubernetes_secret_v1" "azure_dns_config" {
  metadata {
    name      = "azure-dns-config"
    namespace = kubernetes_namespace_v1.external_dns.metadata[0].name
  }

  data = {
    "azure.json" = jsonencode({
      tenantId        = data.azurerm_client_config.current.tenant_id
      subscriptionId  = var.subscription_id
      resourceGroup   = data.azurerm_resource_group.rg.name
      aadClientId     = azuread_application.external_dns.client_id
      aadClientSecret = azuread_application_password.external_dns.value
    })
  }

  type = "Opaque"

  depends_on = [
    azuread_application.external_dns,
    azuread_application_password.external_dns
  ]
}

# Service Account for External DNS
resource "kubernetes_service_account_v1" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = kubernetes_namespace_v1.external_dns.metadata[0].name
  }
}

# ClusterRole for External DNS
resource "kubernetes_cluster_role_v1" "external_dns" {
  metadata {
    name = "external-dns"
  }

  rule {
    api_groups = [""]
    resources  = ["services", "endpoints", "pods", "namespaces"]
    verbs      = ["get", "watch", "list"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "watch", "list"]
  }

  rule {
    api_groups = ["gateway.networking.k8s.io"]
    resources  = ["gateways", "httproutes", "grpcroutes", "tlsroutes", "tcproutes", "udproutes"]
    verbs      = ["get", "watch", "list"]
  }
}

# ClusterRoleBinding for External DNS
resource "kubernetes_cluster_role_binding_v1" "external_dns_viewer" {
  metadata {
    name = "external-dns-viewer"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.external_dns.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.external_dns.metadata[0].name
    namespace = kubernetes_namespace_v1.external_dns.metadata[0].name
  }
}

# Deployment for External DNS
resource "kubernetes_deployment_v1" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = kubernetes_namespace_v1.external_dns.metadata[0].name
  }

  spec {
    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        app = "external-dns"
      }
    }

    template {
      metadata {
        labels = {
          app = "external-dns"
        }
      }

      spec {
        service_account_name = kubernetes_service_account_v1.external_dns.metadata[0].name

        container {
          name  = "external-dns"
          image = "registry.k8s.io/external-dns/external-dns:v0.14.0"

          args = [
            "--source=gateway-httproute",
            "--domain-filter=${data.azurerm_dns_zone.dns.name}",
            "--provider=azure",
            "--azure-resource-group=${data.azurerm_resource_group.rg.name}",
            "--azure-subscription-id=${var.subscription_id}",
            "--txt-owner-id=external-dns",
            "--txt-prefix=external-dns-",
            "--log-level=debug"
          ]

          resources {
            requests = {
              memory = "64Mi"
              cpu    = "50m"
            }
            limits = {
              memory = "128Mi"
              cpu    = "100m"
            }
          }

          volume_mount {
            name       = "azure-config"
            mount_path = "/etc/kubernetes"
            read_only  = true
          }
        }

        volume {
          name = "azure-config"
          secret {
            secret_name = kubernetes_secret_v1.azure_dns_config.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_secret_v1.azure_dns_config,
    kubernetes_service_account_v1.external_dns,
    kubernetes_cluster_role_binding_v1.external_dns_viewer,
    azurerm_role_assignment.external_dns_dns_contributor
  ]
}
