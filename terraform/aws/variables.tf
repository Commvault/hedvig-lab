variable "region" {
  type    = string
  default = "us-east-1"
}
variable "image" {
  type = string
  default = "ami-0affd4508a5d2481b"
}

variable "storage-node-volume-type" {
  type    = string
  default = "gp2"
}
variable "storage-node-volume-size" {
  type    = number
  default = 64
}

variable "keypair_name" {
  type    = string
  default = "hedvig-test"
}

variable "key_path_private" {
  type    = string
  default = "/Users/ericastephens/.ssh/hedvig-test.pem"
}
