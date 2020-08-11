# Lab / demo purposes only. Not for production use.

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

resource "azurerm_resource_group" "rg-hedvig" {
  name     = "rg-hedvig"
  location = var.region
}

resource "azurerm_virtual_network" "vnet-hedvig" {
  name                = "vnet-hedvig"
  resource_group_name = azurerm_resource_group.rg-hedvig.name
  location            = azurerm_resource_group.rg-hedvig.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "sn-public" {
  name                 = "sn-public"
  resource_group_name  = azurerm_resource_group.rg-hedvig.name
  virtual_network_name = azurerm_virtual_network.vnet-hedvig.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "sn-private" {
  name                 = "sn-private"
  resource_group_name  = azurerm_resource_group.rg-hedvig.name
  virtual_network_name = azurerm_virtual_network.vnet-hedvig.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "nsg-public" {
  name                = "nsg-public"
  resource_group_name = azurerm_resource_group.rg-hedvig.name
  location            = azurerm_resource_group.rg-hedvig.location

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_subnet_network_security_group_association" "sn-public-to-nsg-public" {
  subnet_id                 = azurerm_subnet.sn-public.id
  network_security_group_id = azurerm_network_security_group.nsg-public.id
}

resource "azurerm_storage_account" "sa-hedvig" {
  name                     = "sahedvig"
  resource_group_name      = azurerm_resource_group.rg-hedvig.name
  location                 = azurerm_resource_group.rg-hedvig.location
  account_replication_type = "LRS"
  account_tier             = "Standard"
}

# Public jump server; need to replace with Azure-native bastion capabilities
resource "azurerm_public_ip" "pip-jump" {
  name                = "pip-jump"
  resource_group_name = azurerm_resource_group.rg-hedvig.name
  location            = azurerm_resource_group.rg-hedvig.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic-jump" {
  name                = "nic-jump"
  resource_group_name = azurerm_resource_group.rg-hedvig.name
  location            = azurerm_resource_group.rg-hedvig.location

  ip_configuration {
    name                          = "nic-jump-config"
    subnet_id                     = azurerm_subnet.sn-public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-jump.id
  }
}

resource "azurerm_linux_virtual_machine" "vm-jump" {
  name                  = "vm-jump"
  resource_group_name   = azurerm_resource_group.rg-hedvig.name
  location              = azurerm_resource_group.rg-hedvig.location
  network_interface_ids = [azurerm_network_interface.nic-jump.id]
  size                  = var.vm_sizes["proxy"]

  os_disk {
    name                 = "vm-jump-disk-os"
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = var.os_version
    version   = "latest"
  }

  computer_name                   = "vm-jump"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.key_path_public)
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.sa-hedvig.primary_blob_endpoint
  }
}

resource "azurerm_network_security_group" "nsg-private" {
  name                = "nsg-private"
  resource_group_name = azurerm_resource_group.rg-hedvig.name
  location            = azurerm_resource_group.rg-hedvig.location

  security_rule {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22"]
    source_address_prefix      = azurerm_subnet.sn-public.address_prefixes[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "storage-node"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "80", "443", "2181", "3000", "4000", "7000 - 7003", "7010", "7100", "7500", "8000", "8080 - 8081", "8777 - 8778", "8090 - 8096", "11001", "11002", "15000"]
    source_address_prefix      = azurerm_subnet.sn-private.address_prefixes[0]
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "udp"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_ranges    = ["1024 - 65535", "111"]
    source_address_prefix      = azurerm_subnet.sn-private.address_prefixes[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "proxy"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["111", "875", "2049", "2224", "3121", "3260", "21064", "33333", "50000 - 50008", "50022"]
    source_address_prefix      = azurerm_subnet.sn-private.address_prefixes[0]
    destination_address_prefix = "*"
  }

}

resource "azurerm_subnet_network_security_group_association" "sn-private-to-nsg-private" {
  subnet_id                 = azurerm_subnet.sn-private.id
  network_security_group_id = azurerm_network_security_group.nsg-private.id
}

# Hedvig Proxy
resource "azurerm_network_interface" "nic-proxy" {
  name                = "nic-proxy"
  resource_group_name = azurerm_resource_group.rg-hedvig.name
  location            = azurerm_resource_group.rg-hedvig.location

  ip_configuration {
    name                          = "nic-proxy"
    subnet_id                     = azurerm_subnet.sn-private.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm-proxy" {
  name                  = "vm-proxy"
  resource_group_name   = azurerm_resource_group.rg-hedvig.name
  location              = azurerm_resource_group.rg-hedvig.location
  network_interface_ids = [azurerm_network_interface.nic-proxy.id]
  size                  = var.vm_sizes["proxy"]

  os_disk {
    name                 = "vm-proxy-disk-os"
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = var.os_version
    version   = "latest"
  }

  computer_name                   = "vm-proxy"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.key_path_public)
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.sa-hedvig.primary_blob_endpoint
  }

}

resource "azurerm_managed_disk" "vm-proxy-disk0" {
  name                 = "vm-proxy-disk0"
  location             = azurerm_resource_group.rg-hedvig.location
  resource_group_name  = azurerm_resource_group.rg-hedvig.name
  storage_account_type = var.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = 64
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm-proxy-disk0-to-vm-proxy" {
  managed_disk_id    = azurerm_managed_disk.vm-proxy-disk0.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm-proxy.id
  lun                = "10"
  caching            = "ReadWrite"
}

# Hedvig Deployment
resource "azurerm_network_interface" "nic-deployment" {
  name                = "nic-deployment"
  resource_group_name = azurerm_resource_group.rg-hedvig.name
  location            = azurerm_resource_group.rg-hedvig.location

  ip_configuration {
    name                          = "nic-deployment"
    subnet_id                     = azurerm_subnet.sn-private.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm-deployment" {
  name                  = "vm-deployment"
  resource_group_name   = azurerm_resource_group.rg-hedvig.name
  location              = azurerm_resource_group.rg-hedvig.location
  network_interface_ids = [azurerm_network_interface.nic-deployment.id]
  size                  = var.vm_sizes["deployment"]

  os_disk {
    name                 = "vm-deployment-disk-os"
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = var.os_version
    version   = "latest"
  }

  computer_name                   = "vm-deployment"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.key_path_public)
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.sa-hedvig.primary_blob_endpoint
  }
}

resource "azurerm_managed_disk" "vm-deployment-disk0" {
  name                 = "vm-deployment-disk0"
  location             = azurerm_resource_group.rg-hedvig.location
  resource_group_name  = azurerm_resource_group.rg-hedvig.name
  storage_account_type = var.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = 64
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm-deployment-disk0-to-vm-deployment" {
  managed_disk_id    = azurerm_managed_disk.vm-deployment-disk0.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm-deployment.id
  lun                = "10"
  caching            = "ReadWrite"
}

# Hedvig Storage Nodes
module "storagenode0" {
  source                   = "./modules/compute/storagenode"
  node_name                = "storagenode0"
  vm_size                  = var.vm_sizes["storagenode"]
  subscription_id          = var.subscription_id
  resource_group_name      = azurerm_resource_group.rg-hedvig.name
  subnet_id                = azurerm_subnet.sn-private.id
  location                 = azurerm_resource_group.rg-hedvig.location
  storage_account_uri      = azurerm_storage_account.sa-hedvig.primary_blob_endpoint
  storagenode_disk_size_gb = 24
  storagenode_disk_count   = 9
  os_version               = var.os_version
}

module "storagenode1" {
  source                   = "./modules/compute/storagenode"
  node_name                = "storagenode1"
  vm_size                  = var.vm_sizes["storagenode"]
  subscription_id          = var.subscription_id
  resource_group_name      = azurerm_resource_group.rg-hedvig.name
  subnet_id                = azurerm_subnet.sn-private.id
  location                 = azurerm_resource_group.rg-hedvig.location
  storage_account_uri      = azurerm_storage_account.sa-hedvig.primary_blob_endpoint
  storagenode_disk_size_gb = 24
  storagenode_disk_count   = 9
  os_version               = var.os_version
}

module "storagenode2" {
  source                   = "./modules/compute/storagenode"
  node_name                = "storagenode2"
  vm_size                  = var.vm_sizes["storagenode"]
  subscription_id          = var.subscription_id
  resource_group_name      = azurerm_resource_group.rg-hedvig.name
  subnet_id                = azurerm_subnet.sn-private.id
  location                 = azurerm_resource_group.rg-hedvig.location
  storage_account_uri      = azurerm_storage_account.sa-hedvig.primary_blob_endpoint
  storagenode_disk_size_gb = 24
  storagenode_disk_count   = 9
  os_version               = var.os_version
}
