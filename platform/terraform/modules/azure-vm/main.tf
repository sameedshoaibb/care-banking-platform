resource "azurerm_public_ip" "vm_pip" {
  name                = "infra-vm-pip"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Interface
resource "azurerm_network_interface" "vm_nic" {
  name                = "infra-vm-nic"
  location            = var.location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "infra-ipconfig"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_pip.id
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.vm_name}-nsg"
  location            = var.location
  resource_group_name = var.rg_name

  security_rule {
    name                       = "SSH"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "89.0.49.165/32"
    destination_address_prefix = "*"
    description                = "SSH access"
  }

  security_rule {
    name                       = "Jenkins"
    priority                   = 310
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "89.0.49.165/32"
    destination_address_prefix = "*"
    description                = "Jenkins access"
  }

  security_rule {
    name                       = "Nginx"
    priority                   = 320
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8888"
    source_address_prefix      = "89.0.49.165/32"
    destination_address_prefix = "*"
    description                = "Nginx access"
  }

  security_rule {
    name                       = "Argo"
    priority                   = 330
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30080"
    source_address_prefix      = "89.0.49.165/32"
    destination_address_prefix = "*"
    description                = "ArgoCD access"
  }

  security_rule {
    name                        = "Github"
    priority                    = 340
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "8080"
    source_address_prefixes     = ["192.30.252.0/22", "185.199.108.0/22", "140.82.112.0/20", "143.55.64.0/20"]
    destination_address_prefix  = "*"
    description                 = "GitHub infrahooks"
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = var.vm_name
  resource_group_name             = var.rg_name
  location                        = var.location
  size                            = "Standard_D4ls_v5"
  disable_password_authentication = false
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  network_interface_ids           = [azurerm_network_interface.vm_nic.id]

  timeouts {
    create = "30m"
    update = "30m"
    delete = "10m"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

}


