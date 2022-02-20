variable "aws_region" {
  default = "eu-west-3"
}

variable "instance_type" {
  default = "t2.micro"
}

#
# After release remove insecure password
#
variable "db_username" {
  default = "wpuser"
}

variable "db_password" {
  default = "Password1!"
}

#
# After release uncomment
#
# Then run terraform with parameter -var-file="secret.tfvars"
#
# variable "db_username" {
#   description = "Database user name"
#   type = string
#   sensitive = true
# }
#
# variable "db_password" {
#   description = "Database user password"
#   type = string
#   sensitive = true
# }