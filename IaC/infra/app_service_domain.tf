# DNS Zone for the App Service Domain
resource "azurerm_dns_zone" "demo" {
  name                = "${var.base_name}-${var.domain_suffix}.com"
  resource_group_name = azurerm_resource_group.demo.name

  tags = {
    environment = "workshop"
  }
}

# App Service Domain - automatically registers and manages a .com domain
# This will actually purchase and register the domain with Azure
resource "azapi_resource" "app_service_domain" {
  type      = "Microsoft.DomainRegistration/domains@2024-11-01"
  name      = "${var.base_name}-${var.domain_suffix}.com"
  location  = "global"
  parent_id = azurerm_resource_group.demo.id

  body = {
    properties = {
      consent = {
        agreementKeys = [
          "DNPA",
          "DNTA"
        ]
        agreedBy = var.domain_contact_email
        agreedAt = timestamp()
      }
      dnsZoneId = azurerm_dns_zone.demo.id
      contactAdmin = {
        nameFirst = "Workshop"
        nameLast  = "Administrator"
        email     = var.domain_contact_email
        phone     = "+1.5551234567"
        addressMailing = {
          address1   = "123 Workshop Street"
          city       = "Seattle"
          state      = "WA"
          country    = "US"
          postalCode = "98101"
        }
      }
      contactBilling = {
        nameFirst = "Workshop"
        nameLast  = "Administrator"
        email     = var.domain_contact_email
        phone     = "+1.5551234567"
        addressMailing = {
          address1   = "123 Workshop Street"
          city       = "Seattle"
          state      = "WA"
          country    = "US"
          postalCode = "98101"
        }
      }
      contactRegistrant = {
        nameFirst = "Workshop"
        nameLast  = "Administrator"
        email     = var.domain_contact_email
        phone     = "+1.5551234567"
        addressMailing = {
          address1   = "123 Workshop Street"
          city       = "Seattle"
          state      = "WA"
          country    = "US"
          postalCode = "98101"
        }
      }
      contactTech = {
        nameFirst = "Workshop"
        nameLast  = "Administrator"
        email     = var.domain_contact_email
        phone     = "+1.5551234567"
        addressMailing = {
          address1   = "123 Workshop Street"
          city       = "Seattle"
          state      = "WA"
          country    = "US"
          postalCode = "98101"
        }
      }
      privacy       = true
      autoRenew     = true
      dnsType       = "AzureDns"
      targetDnsType = "AzureDns"
    }
  }

  tags = {
    environment = "workshop"
  }

  lifecycle {
    ignore_changes = [
      body
    ]
  }

  depends_on = [azurerm_dns_zone.demo]
}