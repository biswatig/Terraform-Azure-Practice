#azure provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}
#Configure Azure Provider
#using the specific subscription id as I have two subscriptions
provider "azurerm" {
  features {}
  subscription_id = "aff5b933-279e-4f20-9eea-60552917a436"
}

resource "azurerm_resource_group" "rg1" {
  name     = "rg1-terraform"
  location = "East US"
  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1-terraform"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  address_space       = ["10.0.0.0/16"]
  # dns_servers         = ["10.0.0.4", "10.0.0.5"] see next comment line
  tags = {
    environment = "Terraform Demo"
  }
}
#The dns_servers attribute specifies the DNS servers that the VMs within this virtual network will use for name resolution.
#In your configuration, the VMs inside the virtual network will use 10.0.0.4 and 10.0.0.5 as their DNS servers. 
#These IPs would typically belong to DNS servers that you've set up within your network or other reachable networks. 
#If you don't have DNS servers at these addresses, name resolution would fail.
#If you don't specify any DNS servers, the VMs will use Azure's internal DNS servers. lets do that for now !

#creating subnets
resource "azurerm_subnet" "vnet1-subnet1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "vnet1-subnet2" {
  name                 = "subnet2"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/24"]
}

#creating a network security group
resource "azurerm_network_security_group" "nsg1" {
  name                = "nsg1-terraform"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  tags = {
    environment = "Terraform Demo"
  }
}

#creating a network security group rule
resource "azurerm_network_security_rule" "nsg1_rule1" {
  name                        = "nsg1_rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*" #if you want to restrict access to a specific ip address, you can do that here, probably use your own ip addres
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg1.name
  network_security_group_name = azurerm_network_security_group.nsg1.name
}

#creating a newtork subnet security group association and associating it to the subnet
resource "azurerm_subnet_network_security_group_association" "nsg1_vnet1-subnet1" {
  subnet_id                 = azurerm_subnet.vnet1-subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}

resource "azurerm_subnet_network_security_group_association" "nsg1_vnet1-subnet2" {
  subnet_id                 = azurerm_subnet.vnet1-subnet2.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}

#creating a public ip address
resource "azurerm_public_ip" "vnet1-publicip1" {
  name                = "publicip1-terraform"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  allocation_method   = "Dynamic"
  tags = {
    environment = "Terraform Demo"
  }
}

#creating a network interface: it will get the public ip address from the public ip address resource
resource "azurerm_network_interface" "rg1-nic" {
  name                = "rg1-nic"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vnet1-subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vnet1-publicip1.id
  }
  tags = {
    environment = "Terraform Demo"
  }
}

#creating a virtual machine
resource "azurerm_linux_virtual_machine" "rg1-vm1" {
  name                = "rg1-vm1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  size                = "Standard_DS1_v2"
  admin_username      = "azureadmin"
  network_interface_ids = [
    azurerm_network_interface.rg1-nic.id,
  ]

  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "azureadmin"
    public_key = file("~/.ssh/azuressh.pub")
  }

  os_disk {
    name                 = "rg1-vm1-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  provisioner "local-exec" {
    command = templatefile("linux-ssh-script.tpl", {
      hostname      = self.public_ip_address,
      user          = "azureadmin",
      identityfile = "~/.ssh/azuressh"
    })
    interpreter = ["bash", "-c"]
  }

  computer_name = "rg1-vm1"
  tags = {
    environment = "Terraform Demo"
  }
}
#check the public ip address by calling terraform state show on the vm1
#terraform state show azurerm_linux_virtual_machine.rg1-vm1
#to ssh into the vm, use the public ip address and the private key
#to destroy the resources, run terraform destroy

#access the vm using the public ip address: ssh -i ~/.ssh/azurekey azureadmin@<public ip address>
#lsb_release -a : to check the os version
#exit to exit the vm

#utilise the custom data argument to bootstrap the vm and install the docker engine
#this will allow us to have a linux vm instlled with docker ready to go for all out dev needs
#create a new file named customdata.tpl which is a template file usually

#using data source to get the ip address

data "azurerm_public_ip" "rg1-ip-data" {
  name                = azurerm_public_ip.vnet1-publicip1.name
  resource_group_name = azurerm_resource_group.rg1.name
}

output "vm1_ip_address" {
  value = data.azurerm_public_ip.rg1-ip-data.ip_address
}