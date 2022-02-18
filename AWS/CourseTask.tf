#------------------------------------
# Final work on the AWS course
#
# Maintaner: Dmitry Demitov
# email: demitov@gmail.com
#------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.1.0"
      # terraform init показал версию 4.1.0, её и зафиксировал
      # 2022-02-19
    }
  }
}

# провайдер AWS
# регион paris (eu-west-3)
provider "aws" {
  profile = "default"
  region  = "eu-west-3"
}

#------------------------------------
# Create virtual private cloud (VPC)
#------------------------------------
# resource "aws_vpc" "wordpress_vpc" {
#
# }

#------------------------------------
# Create EC2 instances (EC2)
#------------------------------------
resource "aws_instance" "wordpress_ec2" {
  ami                    = "ami-08cfb7b19d5cd546d"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.wordpress_sg.id]
  user_data              = <<EOF
#!/bin/bash
yum -y update
EOF
}

#------------------------------------
# Create security group (SG)
#------------------------------------
resource "aws_security_group" "wordpress_sg" {
  name        = "wordpress_SG"
  description = "HA WordPress Web server"
  # vpc_id      = aws_vpc.main.id

  # входящий трафик по 80 порту с любых внешних адресов по протоколу tcp
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks      = [aws_vpc.main.cidr_block]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  # входящий трафик по 443 порту с любых внешних адресов по протоколу tcp
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks      = [aws_vpc.main.cidr_block]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  # исходящий трафик по 80 порту с любых внешних адресов по протоколу tcp
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }
}
