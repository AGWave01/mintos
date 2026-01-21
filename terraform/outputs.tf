output "sonarqube_url" {
  value = "http://${var.ingress_host}"
}

output "postgres_user" {
  value = var.postgres_user
}

output "postgres_db" {
  value = var.postgres_db
}

output "postgres_password" {
  value     = local.effective_pg_password
  sensitive = true
}
