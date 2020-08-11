# Create NIC
# Create VM (w/ OS disk)
# Create cache disk and attach
# Create metadata disk and attach
# Create storage disks (9)

resource "azurerm_network_interface" "nic-storagenode" {
  name                = format("nic-%s", var.node_name)
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = format("nic-%s", var.node_name)
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm-storagenode" {
  name                  = format("vm-%s", var.node_name)
  resource_group_name   = var.resource_group_name
  location              = var.location
  network_interface_ids = [azurerm_network_interface.nic-storagenode.id]
  size                  = var.vm_size

  os_disk {
    name                 = format("vm-%s-disk-os", var.node_name)
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

  computer_name                   = format("vm-%s", var.node_name)
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.key_path_public)
  }

  boot_diagnostics {
    storage_account_uri = var.storage_account_uri
  }

}

resource "azurerm_managed_disk" "vm-storagenode-cache" {
  name                 = format("vm-%s-cache", var.node_name)
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = 40
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm-storagenode-cache-to-vm-storagenode" {
  managed_disk_id    = azurerm_managed_disk.vm-storagenode-cache.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm-storagenode.id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_managed_disk" "vm-storagenode-metadata" {
  name                 = format("vm-%s-metadata", var.node_name)
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = var.storagenode_disk_size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm-storagenode-metadata-to-vm-storagenode" {
  managed_disk_id    = azurerm_managed_disk.vm-storagenode-metadata.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm-storagenode.id
  lun                = "20"
  caching            = "ReadWrite"
}

# Create the 9 disks and respective attachments to the VM
resource "azurerm_managed_disk" "md" {
  count                = var.storagenode_disk_count
  name                 = format("vm-%s-storage%s", var.node_name, count.index)
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = var.storagenode_disk_size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "mdda" {
  count              = var.storagenode_disk_count
  managed_disk_id    = azurerm_managed_disk.md[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.vm-storagenode.id
  lun                = 30 + count.index
  caching            = "ReadWrite"
}