variable "subscription_id" {
  description = "The subscription ID in which the resources will be created."
  type        = string
  sensitive   = true
}

variable "base_name" {
  description = "The base name for the resources (will be used for prefix)."
  type        = string
}

variable "region" {
  description = "The region in which the resources will be created (example: swedencentral)."
  type        = string
  default     = "northeurope"
}

variable "virtual_network_address_prefix" {
  description = "The address space that is used by the virtual network."
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_subnet_address_prefix" {
  description = "The address space that is used by the AKS subnet."
  type        = string
  default     = "10.0.0.0/18"
}

variable "aks_service_cidr" {
  description = "(Optional) The Network Range used by the Kubernetes service."
  type        = string
  default     = "192.168.0.0/20"
}

variable "aks_dns_service_ip" {
  description = "(Optional) IP address within the Kubernetes service address range that will be used by cluster service discovery (kube-dns)."
  type        = string
  default     = "192.168.0.10"
}

variable "pod_cidr" {
  description = "(Optional) The IP address range used for the pods in the Kubernetes cluster."
  type        = string
  default     = "10.244.0.0/16"
}

variable "agc_subnet_address_prefix" {
  description = "The address space that is used by the Application Gateway for Containers subnet."
  type        = string
  default     = "10.0.64.0/24"
}

variable "domain_suffix" {
  description = "Two digit suffix for the domain name (e.g., '01' for basename-01.com)"
  type        = string
  default     = "01"
}

variable "domain_contact_email" {
  description = "Email address for domain registration (required, cannot use microsoft.com domains)"
  type        = string
}
