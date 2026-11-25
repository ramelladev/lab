terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "27e0a25a-9c96-4a34-9edf-dfcec5252d98"
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-terraform-demo"
  location = "westus2"
}

resource "azurerm_resource_group" "demo_state" {
  name     = "rg-state-demo"
  location = "westus2"
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-demo"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Subnet
resource "azurerm_subnet" "main" {
  name                 = "subnet-demo"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "main" {
  name                = "pip-demo"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
}

# Network Security Group (Firewall Rules)
resource "azurerm_network_security_group" "main" {
  name                = "nsg-demo"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

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

# Network Interface
resource "azurerm_network_interface" "main" {
  name                = "nic-demo"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

# Connect NSG to NIC
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                = "vm-demo"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_B2s_v2"
  admin_username      = "bjr"

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_ssh_key {
    username   = "bjr"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC2t8NI62+iMRMTkmKlUMHKJ4cWk4EYH3Eh0WkszUZ3k6NTUigzXKjmdCn4mO8gK9R7PbzCjaAkRX0G5dDOq75roqmfYEVS92iJSjT3ltxTokydYszCKDLmcayr8vpAhqnx5Y9+EHnKvx0+z3XzYlUZcmvcPgEF84Y3QLPDZqoj0bVjq9SIZOz4EBCdkKF+PHDDDb3Lsvov+9bWU2qSzrOvPDEr96ZRhQMSnKnbcUNO5vXj4nCPf0MW/W9Oml70O2FENb/Lb3wK/g5lHOCnhbOpNod5HHPmTXmFBoPGvwOt7+wtJ+CovAuCRjSvtOczW73PUZ/9i0yRWMqJinzulYM1wvtPe4sCXQeOo+XTacqDprKPKrzQidPQ3PEeBcQaH2TpZ6Bf9ju7s68ExhugWf/fIZrIPso6h2TBtw35HHy0QB5NF41Q6ftEwECaOmGeOv603N4SHVyYXPFHmNVAvp4tKNV75onYgSuORue5bPLLTtbyDu6zaCzFBsfzLFVT+fE="
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

# Output the public IP so we can SSH
output "public_ip" {
  value = azurerm_public_ip.main.ip_address
}

output "ssh_command" {
  value = "ssh bjr@${azurerm_public_ip.main.ip_address}"
}
