# Data source for current client configuration
data "azurerm_client_config" "current" {}

# Key Vault for certificate validation and storage
resource "azurerm_key_vault" "demo" {
  name                       = "${var.base_name}-kv-${var.domain_suffix}"
  location                   = var.region
  resource_group_name        = azurerm_resource_group.demo.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = false

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  rbac_authorization_enabled      = false
  public_network_access_enabled   = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
  }

  # Access policy for the current user (deployment principal)
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    certificate_permissions = [
      "Get",
      "List",
      "Update",
      "Create",
      "Import",
      "Delete",
      "Purge",
      "Recover"
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
      "Recover"
    ]

    key_permissions = [
      "Get",
      "List"
    ]
  }

  # Access policy for App Service Certificate resource provider
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "83ec9573-4262-4994-828d-9a51c2ddaa7e" # Microsoft Azure App Service

    secret_permissions = [
      "Get"
    ]
  }

  # Access policy for Microsoft.Azure.WebSites resource provider
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "22b6abf8-882d-427f-b0c8-e0d1a7ac7b36" # Microsoft Azure WebSites

    certificate_permissions = [
      "Get",
      "List"
    ]

    secret_permissions = [
      "Get",
      "List"
    ]
  }

  tags = {
    environment = "workshop"
  }

  lifecycle {
    ignore_changes = [ 
        access_policy
     ]
  }
}
 