/*
Name: App Load Balancer Network Module
Author: HK Transfield, 2025

Builds a simple Amazon Virtual Private Cloud architecture inside AWS. 
The module creates a VPC with a public subnet for any internet traffic 
and two private subnets intended for an application server and a database.
*/

################################################################################
# GENERAL SETTINGS
################################################################################

locals {
  az_prefixes = ["A", "B"]
}

################################################################################
# Virtual Private Cloud
################################################################################

locals {
  vpc_name = "${var.project_name}-vpc1"
}

resource "aws_vpc" "this" {
  cidr_block                       = var.cidr_block
  instance_tenancy                 = "default"
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name    = local.vpc_name
    Project = var.project_name
  }
}

################################################################################
# Subnets
################################################################################

locals {
  subnet_name = "${local.vpc_name}-sn"
  newbits     = 8
}

resource "aws_subnet" "private" {
  for_each                        = var.private_sn
  vpc_id                          = aws_vpc.this.id
  cidr_block                      = each.value.cidr_block
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.this.ipv6_cidr_block, local.newbits, each.value.ipv6_cidr_block_netnum)
  availability_zone               = each.value.availability_zone
  assign_ipv6_address_on_creation = true

  tags = {
    Name    = "${local.subnet_name}-private-${each.key}"
    Project = var.project_name
  }
}

resource "aws_subnet" "public" {
  for_each                        = var.public_sn
  vpc_id                          = aws_vpc.this.id
  cidr_block                      = each.value.cidr_block
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.this.ipv6_cidr_block, local.newbits, each.value.ipv6_cidr_block_netnum)
  availability_zone               = each.value.availability_zone
  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch         = true

  tags = {
    Name    = "${local.subnet_name}-public-${each.key}"
    Project = var.project_name
  }
}

################################################################################
# Internet Gateway
################################################################################

locals {
  igw_name = "${local.vpc_name}-igw"
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name    = local.igw_name
    Project = var.project_name
  }
}

################################################################################
# Network Address Translation Gateway w/ Elastic IPs
################################################################################

locals {
  nat_gateway_name = "${local.vpc_name}-natgw"
}

resource "aws_nat_gateway" "this" {
  for_each          = aws_subnet.public
  subnet_id         = each.value.id
  allocation_id     = aws_eip.this[each.key].id
  connectivity_type = "public"

  tags = {
    Name    = "${local.nat_gateway_name}-${each.key}"
    Project = var.project_name
  }

  depends_on = [aws_internet_gateway.this] # Recommended to add explicit dependency on IGW for VPC.
}

resource "aws_eip" "this" {
  for_each = toset(local.az_prefixes)
  domain   = "vpc"
}

################################################################################
# Public Route Tables
################################################################################

locals {
  route_table_name = "${local.vpc_name}-rt"
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.this.id
  }

  tags = {
    Name    = "${local.route_table_name}-public"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

################################################################################
# Private Route Tables
################################################################################

resource "aws_route_table" "private" {
  for_each = toset(local.az_prefixes)
  vpc_id   = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this[each.key].id
  }

  tags = {
    Name    = "${local.route_table_name}-private-${each.key}"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

################################################################################
# Security Group
################################################################################

locals {
  sg_name = "${local.vpc_name}-alb-sg"
}

resource "aws_security_group" "this" {
  name        = local.sg_name
  description = "Security group for application load balancer"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name    = local.sg_name
    Project = var.project_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.this.id
  description       = "Allow HTTP from anywhere"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.this.id
  description       = "Allow HTTPS from anywhere"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound" {
  security_group_id = aws_security_group.this.id
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}