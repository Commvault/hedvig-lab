variable "region" {
  type    = string
  default = "eastus"
}

variable "vm_sizes" {
  type = map
  default = {
    proxy      = "Standard_D2_v3"
    deployment = "Standard_D8_v3"
    storagenode = "Standard_D8_v3"
  }
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

variable "os_version" {
  type = string
  default = "7.7"
}
