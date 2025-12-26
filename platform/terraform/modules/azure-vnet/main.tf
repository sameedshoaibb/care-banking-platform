resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.rg_name

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "azurerm_subnet" "infra_subnet" {
  name                 = "Infra-Subnet"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.infra_cidr]

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

