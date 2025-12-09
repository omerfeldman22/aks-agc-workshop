# ========================================
# App1 Resources
# ========================================

resource "kubernetes_namespace_v1" "app1" {
  metadata {
    name = "app1"
    labels = {
      name = "app1"
    }
  }
}

resource "kubernetes_deployment_v1" "app1" {
  metadata {
    name      = "app1"
    namespace = kubernetes_namespace_v1.app1.metadata[0].name
    labels = {
      app = "app1"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "app1"
      }
    }

    template {
      metadata {
        labels = {
          app = "app1"
        }
      }

      spec {
        container {
          name              = "app1"
          image             = "${data.azurerm_container_registry.acr.login_server}/python-server:latest"
          image_pull_policy = "Always"

          env {
            name  = "APP_NAME"
            value = "app1"
          }

          port {
            name           = "http"
            container_port = 8080
          }

          resources {
            requests = {
              memory = "128Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "200m"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }

  depends_on = [docker_registry_image.python_server]
}

resource "kubernetes_service_v1" "app1" {
  metadata {
    name      = "app1"
    namespace = kubernetes_namespace_v1.app1.metadata[0].name
    labels = {
      app = "app1"
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "app1"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }
  }

  depends_on = [kubernetes_deployment_v1.app1]
}

# ========================================
# App2 Resources
# ========================================

resource "kubernetes_namespace_v1" "app2" {
  metadata {
    name = "app2"
    labels = {
      name = "app2"
    }
  }
}

resource "kubernetes_deployment_v1" "app2" {
  metadata {
    name      = "app2"
    namespace = kubernetes_namespace_v1.app2.metadata[0].name
    labels = {
      app = "app2"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "app2"
      }
    }

    template {
      metadata {
        labels = {
          app = "app2"
        }
      }

      spec {
        container {
          name              = "app2"
          image             = "${data.azurerm_container_registry.acr.login_server}/python-server:latest"
          image_pull_policy = "Always"

          env {
            name  = "APP_NAME"
            value = "app2"
          }

          port {
            name           = "http"
            container_port = 8080
          }

          resources {
            requests = {
              memory = "128Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "200m"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }

  depends_on = [docker_registry_image.python_server]
}

resource "kubernetes_service_v1" "app2" {
  metadata {
    name      = "app2"
    namespace = kubernetes_namespace_v1.app2.metadata[0].name
    labels = {
      app = "app2"
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "app2"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }
  }

  depends_on = [kubernetes_deployment_v1.app2]
}
