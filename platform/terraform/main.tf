module "resource_group" {
  source   = "./modules/azure-resource-group"
  rg_name  = var.rg_name
  location = var.location
}

module "network" {
  source        = "./modules/azure-vnet"
  rg_name       = module.resource_group.rg_name
  location      = var.location
  vnet_name     = var.vnet_name
  infra_cidr    = var.infra_cidr
}

module "vm" {
  source               = "./modules/azure-vm"
  rg_name              = module.resource_group.rg_name
  location             = var.location
  subnet_id            = module.network.infra_subnet_id
  vm_name              = var.vm_name
  admin_username       = var.admin_username
  admin_password       = var.admin_password
}
