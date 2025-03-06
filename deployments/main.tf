/*
Name:     Root Module
Project:  AWS Generative AI Backed IDP Solution
Author:   HK Transfield, 2024

This configuration deploys and IDP Streamlit application into
an ECS container that is accessible via the internet. The app
is made highliy available by using an Application Load Balancer.
*/

provider "aws" {
  region = var.region
}

locals {
  project_org  = "hkt"
  project_tag  = "idp"
  project_name = "${local.project_org}-${local.project_tag}"
}

locals {
  lambda_filenames = {
    "1-start-textract-async-detection-job"       = "start-textract-async-detection-job.zip"
    "2-classify-textract-output"                 = "classify-textract-output.zip"
    "3-entity-extraction-and-content-enrichment" = "entity-extraction-and-content-enrichment.zip"
    "4-results-validation"                       = "results-validation.zip"
    "5-human-review-and-validation"              = "human-review-and-validation.zip"
  }
}

################################################################################
# STREAMLIT NETWORK
################################################################################

data "aws_availability_zones" "available" {}

locals {
  az_a = data.aws_availability_zones.available.names[0]
  az_b = data.aws_availability_zones.available.names[1]
}

module "streamlit_network" {
  source     = "../modules/app-network"
  cidr_block = "10.17.0.0/16"
  region     = var.region

  private_sn = {
    "A" = {
      cidr_block             = "10.17.32.0/20"
      ipv6_cidr_block_netnum = 2
      availability_zone      = local.az_a
    }
    "B" = {
      cidr_block             = "10.17.48.0/20"
      ipv6_cidr_block_netnum = 6
      availability_zone      = local.az_b
    }
  }

  public_sn = {
    "A" = {
      cidr_block             = "10.17.96.0/20"
      ipv6_cidr_block_netnum = 3
      availability_zone      = local.az_a
    }
    "B" = {
      cidr_block             = "10.17.112.0/20"
      ipv6_cidr_block_netnum = 7
      availability_zone      = local.az_b
    }
  }

  project_name = local.project_name
  project_tags = {
    project = local.project_tag
  }
}

################################################################################
# STREAMLIT LOAD BALANCER AND CONTAINER
################################################################################

module "streamlit_load_balancer" {
  source      = "../modules/app-load-balancer"
  app_name    = "streamlit"
  vpc_id      = module.streamlit_network.vpc_id
  subnet_ids  = [module.streamlit_network.public_a_subnet_id, module.streamlit_network.public_b_subnet_id]
  domain_name = "" # TODO: Add domain name

  tags = {
    project = local.project_tag
    name    = "streamlit"
  }
}

module "streamlit_container" {
  source = "../modules/app-container"

  app_name             = "streamlit"
  docker_image         = "" # TODO: Add docker imag
  bucket_name          = "" # TODO: Add bucket name
  vpc_id               = module.streamlit_network.vpc_id
  subnet_ids           = [module.streamlit_network.private_a_subnet_id, module.streamlit_network.private_b_subnet_id]
  alb_target_group_arn = module.streamlit_load_balancer.target_group_arn
  container_port       = 8501

  tags = {
    project = local.project_tag
    name    = "streamlit"
  }
}