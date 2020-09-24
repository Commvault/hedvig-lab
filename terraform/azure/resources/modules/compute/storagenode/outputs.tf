output "storagenode_ip_private" {
  value = azurerm_linux_virtual_machine.vm-storagenode.private_ip_addresses
}
