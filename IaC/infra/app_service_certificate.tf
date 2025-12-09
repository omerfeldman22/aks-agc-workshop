# App Service Certificate Order for wildcard domain
# This creates a purchased SSL/TLS certificate for *.yourdomain.com
resource "azurerm_app_service_certificate_order" "wildcard" {
  name                = "${var.base_name}-${var.domain_suffix}-wildcard"
  resource_group_name = azurerm_resource_group.demo.name
  location            = "global"
  
  distinguished_name = "CN=*.${var.base_name}-${var.domain_suffix}.com"
  product_type       = "WildCard"
  validity_in_years  = 1
  auto_renew         = true
  key_size           = 2048

  tags = {
    environment = "workshop"
  }

  depends_on = [azapi_resource.app_service_domain]
}

