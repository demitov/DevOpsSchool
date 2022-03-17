# input vars module

variable "allow-subnets" {
  description = "Allow subnets"
  type        = list(any)
}

variable "allow-sg" {
  description = "Allow securiry group"
  type        = list(any)
}

variable "db-name" {
  description = "Database name"
  type        = string
  default     = "dbname"
}

variable "db-username" {
  description = "Database username"
  type        = string
  default     = "dbuser"
}

variable "db-password" {
  description = "Database user password"
  type        = string
  default     = "Password1!"
}
