# ========================================
# Gateway Namespace and TLS Secret
# ========================================
# Gateway resource is in gateway_resources.tf
# HTTPRoute resources will be created manually in workshop steps

# Namespace for Gateway resources
resource "kubernetes_namespace_v1" "gateway_namespace" {
  metadata {
    name = "app-networking"
    labels = {
      name = "app-networking"
    }
  }
}

# Data source to get Key Vault
data "azurerm_key_vault" "kv" {
  name                = "${var.base_name}-kv-01"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Get all secrets from Key Vault to find the certificate
data "azurerm_key_vault_secrets" "all_secrets" {
  key_vault_id = data.azurerm_key_vault.kv.id
}

# Find the certificate secret (starts with base_name-domain_suffix-wildcard)
locals {
  cert_secret_name = [
    for secret in data.azurerm_key_vault_secrets.all_secrets.names :
    secret if startswith(secret, "${var.base_name}-${var.domain_suffix}-wildcard")
  ][0]
}

# Data source to get certificate secret from Key Vault
# App Service Certificate stores the cert as a secret with GUID suffix
data "azurerm_key_vault_secret" "wildcard_cert" {
  name         = local.cert_secret_name
  key_vault_id = data.azurerm_key_vault.kv.id
}

# Convert PFX to PEM format using local-exec
resource "null_resource" "convert_pfx_to_pem" {
  triggers = {
    cert_version = data.azurerm_key_vault_secret.wildcard_cert.version
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Decode PFX from base64
      echo "${data.azurerm_key_vault_secret.wildcard_cert.value}" | base64 -d > ${path.module}/cert.pfx
      
      # Extract certificate
      openssl pkcs12 -in ${path.module}/cert.pfx -nokeys -passin pass: -clcerts | \
        openssl x509 > ${path.module}/tls.crt
      
      # Extract private key
      openssl pkcs12 -in ${path.module}/cert.pfx -nocerts -passin pass: -passout pass: -nodes > ${path.module}/tls.key
      
      # Clean up PFX
      rm ${path.module}/cert.pfx
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/tls.crt ${path.module}/tls.key"
  }
}

# Read converted certificate files
data "local_file" "tls_crt" {
  depends_on = [null_resource.convert_pfx_to_pem]
  filename   = "${path.module}/tls.crt"
}

data "local_file" "tls_key" {
  depends_on = [null_resource.convert_pfx_to_pem]
  filename   = "${path.module}/tls.key"
}

# TLS Certificate Secret for Kubernetes
resource "kubernetes_secret_v1" "tls_cert" {
  depends_on = [
    data.local_file.tls_crt,
    data.local_file.tls_key
  ]

  metadata {
    name      = "web-app-tls-cert"
    namespace = kubernetes_namespace_v1.gateway_namespace.metadata[0].name
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = data.local_file.tls_crt.content
    "tls.key" = data.local_file.tls_key.content
  }
}