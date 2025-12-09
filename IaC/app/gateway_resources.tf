# ========================================
# Gateway Resource
# ========================================

# Gateway resource
resource "kubectl_manifest" "gateway" {
  yaml_body = <<-YAML
    apiVersion: gateway.networking.k8s.io/v1
    kind: Gateway
    metadata:
      name: app-gateway
      namespace: ${kubernetes_namespace_v1.gateway_namespace.metadata[0].name}
      annotations:
        alb.networking.azure.io/alb-name: alb-networking
        alb.networking.azure.io/alb-namespace: alb-networking
    spec:
      gatewayClassName: azure-alb-external
      listeners:
      - name: https-listener
        protocol: HTTPS
        port: 443
        allowedRoutes:
          namespaces:
            from: Same
        tls:
          mode: Terminate
          certificateRefs:
          - kind: Secret
            name: ${kubernetes_secret_v1.tls_cert.metadata[0].name}
      - name: http-listener
        protocol: HTTP
        port: 80
        allowedRoutes:
          namespaces:
            from: Same
  YAML

  depends_on = [
    kubernetes_secret_v1.tls_cert,
    kubectl_manifest.application_load_balancer,
    time_sleep.wait_for_alb_crd
  ]
}

# ========================================
# ReferenceGrants
# ========================================

# ReferenceGrant to allow HTTPRoutes in app-networking to reference Services in app1
resource "kubectl_manifest" "reference_grant_app1" {
  yaml_body = <<-YAML
    apiVersion: gateway.networking.k8s.io/v1beta1
    kind: ReferenceGrant
    metadata:
      name: allow-app-networking-to-app1
      namespace: ${kubernetes_namespace_v1.app1.metadata[0].name}
    spec:
      from:
      - group: gateway.networking.k8s.io
        kind: HTTPRoute
        namespace: ${kubernetes_namespace_v1.gateway_namespace.metadata[0].name}
      to:
      - group: ""
        kind: Service
  YAML

  depends_on = [
    kubernetes_namespace_v1.app1,
    kubernetes_namespace_v1.gateway_namespace
  ]
}

# ReferenceGrant to allow HTTPRoutes in app-networking to reference Services in app2
resource "kubectl_manifest" "reference_grant_app2" {
  yaml_body = <<-YAML
    apiVersion: gateway.networking.k8s.io/v1beta1
    kind: ReferenceGrant
    metadata:
      name: allow-app-networking-to-app2
      namespace: ${kubernetes_namespace_v1.app2.metadata[0].name}
    spec:
      from:
      - group: gateway.networking.k8s.io
        kind: HTTPRoute
        namespace: ${kubernetes_namespace_v1.gateway_namespace.metadata[0].name}
      to:
      - group: ""
        kind: Service
  YAML

  depends_on = [
    kubernetes_namespace_v1.app2,
    kubernetes_namespace_v1.gateway_namespace
  ]
}
