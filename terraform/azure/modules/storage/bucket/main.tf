# Create a bucket for the software; upload is manual

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

resource "azurerm_resource_group" "sghvsoftware" {
  name     = "sghvsoftware"
  location = var.region
}

resource "azurerm_storage_account" "sahvsoftware" {
  name                     = "sahvsoftware"
  resource_group_name      = azurerm_resource_group.sghvsoftware.name
  location                 = azurerm_resource_group.sghvsoftware.location
  account_replication_type = "LRS"
  account_tier             = "Standard"
}

resource "azurerm_storage_container" "schvsoftware" {
  name                  = "schvsoftware"
  storage_account_name  = azurerm_storage_account.sahvsoftware.name
  container_access_type = "private"
}
