variable "project_name" {
  type    = string
  default = "desafio-tecnico"
}

variable "proxy_port" {
  type    = number
  default = 8080
}

variable "postgres_db" {
  type = string
}

variable "postgres_user" {
  type = string
}

variable "postgres_password" {
  description = "Password PostgreSQL"
  type        = string
  sensitive   = true
}

variable "cadvisor_port" {
  type    = number
  default = 8081
}

