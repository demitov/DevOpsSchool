# Create subnet group
resource "aws_db_subnet_group" "rds-subnet-group" {
  name       = "db subnet group"
  subnet_ids = var.allow-subnets
}

# generate db username password
resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "aws_db_instance" "tf-db" {
  identifier             = "rds-demitov"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  port                   = "3306"
  multi_az               = false
  storage_encrypted      = false
  skip_final_snapshot    = true
  storage_type           = "gp2"
  allocated_storage      = 20
  max_allocated_storage  = 0
  db_subnet_group_name   = aws_db_subnet_group.rds-subnet-group.name
  vpc_security_group_ids = var.allow-sg
  db_name                = var.db-name
  username               = var.db-username
  password               = random_password.db_password.result #?!

  tags = {
    Name  = "RDS"
    Owner = "dmitrii_demitov@epam.com"
  }
}
