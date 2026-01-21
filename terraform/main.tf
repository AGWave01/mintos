locals {
  pg_service_name = "postgresql"
  pg_port         = 5432
}

resource "kubernetes_namespace" "ns" {
  metadata {
    name = var.namespace
  }
}

resource "random_password" "pg" {
  length  = 24
  special = false
}

locals {
  effective_pg_password = var.postgres_password != "" ? var.postgres_password : random_password.pg.result
}

provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "postgresql" {
  name      = local.pg_service_name
  namespace = kubernetes_namespace.ns.metadata[0].name
  chart     = "${path.module}/../helm/postgresql"

  values = [
    yamlencode({
      postgres = {
        db       = var.postgres_db
        user     = var.postgres_user
        password = local.effective_pg_password
      }
      persistence = {
        enabled = true
        size    = "8Gi"
      }
    })
  ]
}

resource "helm_release" "sonarqube" {
  name       = "sonarqube"
  namespace  = kubernetes_namespace.ns.metadata[0].name
  repository = "https://SonarSource.github.io/helm-chart-sonarqube"
  chart      = "sonarqube"

  depends_on = [helm_release.postgresql]

  timeout = 700
  wait    = true

  values = [
    yamlencode({
      community = {
        enabled = true
      }
      monitoringPasscode = "mintos123mintos"
      postgresql = {
        enabled = false
      }

      persistence = {
        enabled = true
        size    = "10Gi"
      }

      jdbcOverwrite = {
        enable       = true
        jdbcUrl      = "jdbc:postgresql://${local.pg_service_name}.${var.namespace}.svc.cluster.local:${local.pg_port}/${var.postgres_db}"
        jdbcUsername = var.postgres_user
        jdbcPassword = local.effective_pg_password
      }

      ingress = {
        enabled = true
        annotations = {
          "kubernetes.io/ingress.class"                 = "nginx"
          "nginx.ingress.kubernetes.io/proxy-body-size" = "64m"
        }
        hosts = [
          {
            name = var.ingress_host
            path = "/"
          }
        ]
      }

      startupProbe = {
        enabled = true
      }
    })
  ]
}
