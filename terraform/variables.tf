variable "namespace" {
  type    = string
  default = "sonarqube"
}

variable "ingress_host" {
  type = string
}

variable "postgres_db" {
  type    = string
  default = "sonarqube"
}

variable "postgres_user" {
  type    = string
  default = "sonarqube"
}

variable "postgres_password" {
  type      = string
  sensitive = true
  default   = ""
}
