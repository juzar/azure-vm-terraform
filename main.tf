# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"  # Specify a version to avoid surprises
    }
  }

  # Configure Azure Remote State Management
  backend "azurerm" {
    resource_group_name  = "myResourceGroup"        # Replace with your Resource Group name for the state file
    storage_account_name = "terraformprovideraz"    # Replace with your Storage Account name for the state file
    container_name       = "terraformprovider"           # Replace with your Container name for the state file
    key                  = "terraform.tfstate" # Name of the state file
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

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

# Create a Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create a Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "my-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

# Create a Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "my-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a Public IP Address
resource "azurerm_public_ip" "public_ip" {
  name                = "my-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
}

# Create a Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "my-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Create the Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_DS1_v2" # Small size for testing
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    name                 = "my-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name  = "myvm"
  admin_username = "azureuser"
  admin_password = "Password123!" # DO NOT use this in production. Use SSH keys or Azure Key Vault!
  disable_password_authentication = false # Should be true in production with SSH keys enabled.
}

output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
}