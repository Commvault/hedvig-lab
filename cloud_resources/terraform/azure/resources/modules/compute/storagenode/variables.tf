variable "vm_size" {
  type = string
}

variable "storage_account_type" {
  type    = string
  default = "Standard_LRS"
}

variable "key_path_public" {
  type    = string
  default = "~/.ssh/hedvig.pub"
}

variable "subscription_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet_id" {
  type = string
}
variable "storage_account_uri" {
  type = string
}
variable "node_name" {
  type = string
}

variable "storagenode_disk_count" {
  type = number
}

variable "storagenode_disk_size_gb" {
  type    = number
  default = 24
}

variable "os_version" {
  type = string
}
