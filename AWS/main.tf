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
  required_version = "~>1.0"
}

# провайдер AWS
provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  default_tags {
    tags = {
      Owner = "Dmitry Demitov"
    }
  }
}

# Get a list of availability zones
data "aws_availability_zones" "available" {
  state = "available"
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

# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "VPC"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "IGW"
  }
}

# Add route to IGW in VPC main route table
resource "aws_route" "route-to-igw" {
  route_table_id         = aws_vpc.vpc.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Create first subnet
resource "aws_subnet" "subnet-a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Subnet in ${data.aws_availability_zones.available.names[0]}"
  }
}
# Create route association
resource "aws_route_table_association" "rta-subnet-a" {
  subnet_id      = aws_subnet.subnet-a.id
  route_table_id = aws_vpc.vpc.main_route_table_id
}

resource "aws_subnet" "subnet-b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "Subnet in ${data.aws_availability_zones.available.names[1]}"
  }
}
# Create route association
resource "aws_route_table_association" "rta-subnet-b" {
  subnet_id      = aws_subnet.subnet-b.id
  route_table_id = aws_vpc.vpc.main_route_table_id
}


# ----------------------------------
# Create EC2 instances (EC2)
resource "aws_instance" "wp-ec2-a" {
  ami                         = data.aws_ami.amazon-linux.id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.sg-ec2.id]
  subnet_id                   = aws_subnet.subnet-a.id
  associate_public_ip_address = true
  user_data = templatefile("userdata.tpl", {
    efs         = aws_efs_file_system.efs-fs.id
    db_host     = aws_db_instance.wp-db.endpoint
    db_name     = var.db_name
    db_username = var.db_username
    db_password = var.db_password
    url         = aws_lb.wp-lb.dns_name
  })
  depends_on = [aws_db_instance.wp-db, aws_lb.wp-lb]

  tags = {
    Name = "WP EC2 in ${data.aws_availability_zones.available.names[0]}"
  }
}

resource "aws_instance" "wp-ec2-b" {
  ami                         = data.aws_ami.amazon-linux.id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.sg-ec2.id]
  subnet_id                   = aws_subnet.subnet-b.id
  associate_public_ip_address = true
  user_data = templatefile("userdata.tpl", {
    efs         = aws_efs_file_system.efs-fs.id
    db_host     = aws_db_instance.wp-db.endpoint
    db_name     = var.db_name
    db_username = var.db_username
    db_password = var.db_password
    url         = aws_lb.wp-lb.dns_name
  })
  depends_on = [aws_db_instance.wp-db, aws_lb.wp-lb]

  tags = {
    Name = "WP EC2 in ${data.aws_availability_zones.available.names[1]}"
  }
}

# Create Security Group HTTP allow
resource "aws_security_group" "sg-ec2" {
  name        = "SG_for_EC2"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "Allow all inbound traffic on the 80 port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "SG HTTP Allow"
  }
}

# ----------------------------------
# Create EFS File System
resource "aws_efs_file_system" "efs-fs" {
  creation_token = "EFS_File_System"
  encrypted      = true
  tags = {
    Name = "EFS File System"
  }
}

# Security goup for EFS
resource "aws_security_group" "sg-efs" {
  name        = "SG_for_EFS"
  description = "Allow NFS inbound traffic"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description     = "NFS from EC2"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.sg-ec2.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "SG for EFS"
  }
}

# Targets for EFS FS
# wp_efs_mnt_tgt_a for subnet_a
resource "aws_efs_mount_target" "wp-efs-mnt-tgt-a" {
  file_system_id  = aws_efs_file_system.efs-fs.id
  subnet_id       = aws_subnet.subnet-a.id
  security_groups = [aws_security_group.sg-efs.id]
  depends_on      = [aws_efs_file_system.efs-fs, aws_security_group.sg-ec2]
}
# wp_efs_mnt_tgt_b for subnet_b
resource "aws_efs_mount_target" "wp-efs-mnt-tgt-b" {
  file_system_id  = aws_efs_file_system.efs-fs.id
  subnet_id       = aws_subnet.subnet-b.id
  security_groups = [aws_security_group.sg-efs.id]
  depends_on      = [aws_efs_file_system.efs-fs, aws_security_group.sg-ec2]
}


# --------------------------------------
# Create Relation Database Service (RDS)
# Create Subnet for RDS
resource "aws_db_subnet_group" "rds-subnet-group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.subnet-a.id, aws_subnet.subnet-b.id]
}

# Create RDS Securty Group
resource "aws_security_group" "sg-rds" {
  name        = "SG_for_RDS"
  description = "Allow MySQL inbound traffic"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description     = "RDS from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg-ec2.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "SG for RDS"
  }
}

# Create MySql instance (RDS)
resource "aws_db_instance" "wp-db" {
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  storage_type           = "gp2"
  allocated_storage      = 20
  max_allocated_storage  = 0
  db_subnet_group_name   = aws_db_subnet_group.rds-subnet-group.name
  vpc_security_group_ids = [aws_security_group.sg-rds.id]
  skip_final_snapshot    = true
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  depends_on             = [aws_security_group.sg-rds, aws_db_subnet_group.rds-subnet-group]

  tags = {
    Name = "RDS"
  }
}


# ----------------------------------
# Create Load Balancer (ALB)
resource "aws_lb" "wp-lb" {
  name                       = "LoadBalancer"
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = [aws_subnet.subnet-a.id, aws_subnet.subnet-b.id]
  security_groups            = [aws_security_group.sg-ec2.id]
  enable_deletion_protection = false

  tags = {
    Name = "WP Load Balancer"
  }
}

# Create Target Group
resource "aws_lb_target_group" "wp-lb-tg" {
  name     = "TargetGroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}

# Create Listener 80 port
resource "aws_lb_listener" "wp-lb" {
  load_balancer_arn = aws_lb.wp-lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wp-lb-tg.arn
  }
}

# Register wp-ec2-a in TG
resource "aws_lb_target_group_attachment" "tg-attach-wp-a" {
  target_group_arn = aws_lb_target_group.wp-lb-tg.arn
  target_id        = aws_instance.wp-ec2-a.id
  port             = 80
}

# Register wp-ec2-b in TG
resource "aws_lb_target_group_attachment" "tg-attach-wp-b" {
  target_group_arn = aws_lb_target_group.wp-lb-tg.arn
  target_id        = aws_instance.wp-ec2-b.id
  port             = 80
}

# ----------------------------------
# Output LoadBalancer DNS Name
output "Balancer-Wordpress" {
  value = "http://${aws_lb.wp-lb.dns_name}"
}
