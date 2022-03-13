variable "aws_region" {
  type    = string
  default = "eu-west-3"
}

variable "owner" {
  type    = string
  default = "Dmitry Demitov"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "instance_ami" {
  type    = string
  default = "ami-081d70d1abe7c706e"
}

variable "key_name" {
  type    = string
  default = "demitov"
}

variable "user_data" {
  default = "template_file(user_data.tpl)"
}

#
# After release remove insecure password
#
variable "db_name" {
  type    = string
  default = "wpdb"
}
variable "db_username" {
  type    = string
  default = "wpuser"
}

variable "db_password" {
  type    = string
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
