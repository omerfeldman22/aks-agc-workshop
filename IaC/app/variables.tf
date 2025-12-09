variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "base_name" {
  description = "Base name for resources"
  type        = string
}

variable "domain_suffix" {
  description = "Domain suffix for DNS zone"
  type        = string
  default     = "01"
}
