variable "client_id" {}

variable "client_secret" {}

variable "address_space" {
  default = ["10.0.0.0/8"]
}

variable "aks_address_prefix" {
  default = "10.240.0.0/16"
}

variable "aci_address_prefix" {
  default = "10.241.0.0/16"
}

variable "environment" {
  default = "aksworkshop"
}

variable "kubernetes_version" {
  default = "1.12.5"
}

variable "tags" {
  type = "map"

  default = {
    create_for = "aksworkshop"
  }
}

variable "location" {
  default = "eastus2"
}
