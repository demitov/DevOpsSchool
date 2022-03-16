#------------------------------------
# Maintainer: Dmitrii Demitov
# email: dmitrii_demitov@epam.com
#------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.1.0"
    }
  }
  required_version = "~>1.0"
}

provider "aws" {
  region = "eu-central-1"
}

# -------------------------------
# Data

data "aws_vpcs" "allow-vpcs" {}

data "aws_subnets" "allow-subnets" {
  filter {
    name   = "vpc-id"
    values = data.aws_vpcs.allow-vpcs.ids
  }
}

data "aws_security_groups" "allow-sg" {
  filter {
    name   = "vpc-id"
    values = data.aws_vpcs.allow-vpcs.ids
  }
}

# -------------------------------
# Outputs

output "allow-vpcs" {
  value = data.aws_vpcs.allow-vpcs.ids
}

output "allow-subnets" {
  value = data.aws_subnets.allow-subnets.ids
}

output "allow-sg" {
  value = data.aws_security_groups.allow-sg
}
