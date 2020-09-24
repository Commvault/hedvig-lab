# Create a bucket for the software; upload is manual

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

resource "azurerm_resource_group" "rghedvigsw" {
  name     = "rghedvigsw"
  location = var.region
}

resource "azurerm_storage_account" "sahedvigsw" {
  name                     = "sahedvigsw"
  resource_group_name      = azurerm_resource_group.rghedvigsw.name
  location                 = azurerm_resource_group.rghedvigsw.location
  account_replication_type = "LRS"
  account_tier             = "Standard"
}

resource "azurerm_storage_container" "schedvigsw" {
  name                  = "schedvigsw"
  storage_account_name  = azurerm_storage_account.sahedvigsw.name
  container_access_type = "private"
}
