variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "subscription_id" {}

variable "rg_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "Infrastructure-rg"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "UK West"
}

variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
  default     = "infra-vnet-prod"
}

variable "infra_cidr" {
  description = "CIDR block for the infrastructure network"
  type        = string
  default     = "10.0.1.0/24"
}

variable "vm_name" {
  description = "Name of the Infrastructure virtual machine"
  type        = string
  default     = "Infrastructure-vm"
}

variable "admin_username" {
  description = "Admin username for the virtual machine"
  type        = string
  default     = "sameed"
}

variable "admin_password" {
  description = "Admin password for the virtual machine"
  type        = string
  default     = "Admin1234!!!!!" #  Change this for production
  sensitive   = true
}


