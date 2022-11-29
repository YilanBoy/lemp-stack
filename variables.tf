variable "ssh_public_key_filepath" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}

variable "mysql_root_password" {
  type = string
}

variable "mysql_database_name" {
  type = string
}

variable "mysql_user" {
  type = string
}

variable "mysql_password" {
  type = string
}

variable "redis_password" {
  type = string
}
