#------------------------------------
# Final work on the AWS course
#
# Maintainer: Dmitry Demitov
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

# получаем список доступых в регионе зон
data "aws_availability_zones" "available" {
  state = "available"
}

#------------------------------------
# Create Virtual Private Cloud (VPC)
#------------------------------------
# Local Network IP range
# 10.0.0.0    - 10.255.255.255.255
# 172.16.0.0  - 172.31..255.255
# 192.168.0.0 - 192.168.255.255

resource "aws_vpc" "wordpress_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name  = "WordPress VPC"
    Owner = "Dmitry Demitov"
  }
}

#------------------------------------
# Create first subnet
#------------------------------------
resource "aws_subnet" "wordpress_subnet_a" {
  vpc_id            = aws_vpc.wordpress_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name  = "WordPress Subnet ${data.aws_availability_zones.available.names[0]}"
    Owner = "Dmitry Demitov"
  }
}

#------------------------------------
# Create second subnet
#------------------------------------
resource "aws_subnet" "wordpress_subnet_b" {
  vpc_id            = aws_vpc.wordpress_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name  = "WordPress Subnet ${data.aws_availability_zones.available.names[1]}"
    Owner = "Dmitry Demitov"
  }
}

#------------------------------------
# Create EC2 instances (EC2)
#------------------------------------
resource "aws_instance" "wordpress_ec2_a" {
  ami                    = "ami-08cfb7b19d5cd546d"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.wordpress_sg.id]
  subnet_id = aws_subnet.wordpress_subnet_a.id

  tags = {
    Name  = "WordPress EC2"
    Owner = "Dmitry Demitov"
  }
}

#------------------------------------
# Create EC2 instances (EC2)
#------------------------------------
resource "aws_instance" "wordpress_ec2_b" {
  ami                    = "ami-08cfb7b19d5cd546d"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.wordpress_sg.id]
  subnet_id = aws_subnet.wordpress_subnet_b.id
  
  tags = {
    Name  = "WordPress EC2"
    Owner = "Dmitry Demitov"
  }
}

#------------------------------------
# Create security group (SG)
#------------------------------------
resource "aws_security_group" "wordpress_sg" {
  name        = "wordpress_SG"
  description = "HA WordPress Web server"
  vpc_id      = aws_vpc.wordpress_vpc.id

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

  tags = {
    Name  = "WordPress SG"
    Owner = "Dmitry Demitov"
  }
}
