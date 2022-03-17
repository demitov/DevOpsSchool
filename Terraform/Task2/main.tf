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
  backend "s3" {
    bucket  = "tf-state-demitov"
    encrypt = true
    key     = "terraform.tfstate"
    region  = "eu-central-1"
  }
  required_version = "~>1.0"
}

provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      Owner = "dmitrii_demitov@epam.com"
    }
  }
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
  filter {
    name   = "group-name"
    values = ["epam-by-ru"]
  }
}

# Get AMI for last Amazon Linux EC2
data "aws_ami" "amazon-linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
  }
  owners = ["amazon"]
}

# -------------------------------
# EC2 instance
resource "aws_instance" "nginx" {
  ami                    = data.aws_ami.amazon-linux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = data.aws_security_groups.allow-sg.ids
  subnet_id              = data.aws_subnets.allow-subnets.ids[0]
  key_name               = "dmitrii_demitov@epam.com"
  user_data              = templatefile("userdata.tpl", {})

  tags = {
    Name  = "Nginx"
    Owner = "dmitrii_demitov@epam.com"
  }
  volume_tags = {
    Owner = "dmitrii_demitov@epam.com"
  }
}

module "rds" {
  source        = "./modules/rds"
  allow-subnets = data.aws_subnets.allow-subnets.ids
  allow-sg      = data.aws_security_groups.allow-sg.ids
}

# output "allow-subnets" {
#   value = data.aws_subnets.allow-subnets.ids
# }
output "nginx-public_dns" {
  value = aws_instance.nginx.public_dns
}
