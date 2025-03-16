# Define variables
variable "resource_group_name" {
  type    = string
  default = "vm-rg"
}

variable "location" {
  type    = string
  default = "East US"
}

variable "vm_name" {
  type    = string
  default = "my-vm"
}