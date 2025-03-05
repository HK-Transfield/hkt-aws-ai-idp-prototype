variable "project_name" {
  description = "For naming resources according to the project"
  type        = string
}

variable "project_tags" {
  type = map(string)
}

variable "region" {
  type    = string
  default = "ap-southeast-2"
}

################################################################################
# VPC Configuration
################################################################################

variable "cidr_block" {
  description = "CIDR block for VPC"
  type        = string
}

################################################################################
# Subnet Configurations
################################################################################

variable "private_sn" {
  description = "Private application subnet CIDR values"
  type = map(object({
    cidr_block             = string
    ipv6_cidr_block_netnum = number
    availability_zone      = string
  }))
}

variable "public_sn" {
  description = "Public web subnet CIDR values"
  type = map(object({
    cidr_block             = string
    ipv6_cidr_block_netnum = number
    availability_zone      = string
  }))
}