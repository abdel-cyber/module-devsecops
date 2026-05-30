terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# Provider Kubernetes - Utilise le kubeconfig pour se connecter au cluster production
provider "kubernetes" {
  config_path = var.kubeconfig_path
}

# Namespace pour production
resource "kubernetes_namespace" "production" {
  metadata {
    name = "tp-devsecops-production"
    labels = {
      environment = "production"
      project     = "tp-devsecops"
    }
  }
}

# Secret pour accéder au GitLab Container Registry
resource "kubernetes_secret" "gitlab_registry" {
  metadata {
    name      = "gitlab-registry-secret"
    namespace = kubernetes_namespace.production.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.registry_url}" = {
          username = var.registry_user
          password = var.registry_password
          email    = var.registry_email
          auth     = base64encode("${var.registry_user}:${var.registry_password}")
        }
      }
    })
  }
}

# Deployment avec 3 pods (haute disponibilité en production)
resource "kubernetes_deployment" "app" {
  metadata {
    name      = "devsecops-app"
    namespace = kubernetes_namespace.production.metadata[0].name
    labels = {
      app         = "devsecops-app"
      environment = "production"
    }
  }

  spec {
    replicas = 3  # 3 pods pour haute disponibilité

    selector {
      match_labels = {
        app = "devsecops-app"
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "1"
        max_unavailable = "0"  # Zero downtime en production
      }
    }

    template {
      metadata {
        labels = {
          app         = "devsecops-app"
          environment = "production"
        }
      }

      spec {
        image_pull_secrets {
          name = kubernetes_secret.gitlab_registry.metadata[0].name
        }

        container {
          name  = "devsecops-app"
          image = "${var.docker_image}:${var.docker_tag}"

          port {
            container_port = 3000
            name           = "http"
            protocol       = "TCP"
          }

          env {
            name  = "NODE_ENV"
            value = "production"
          }

          env {
            name  = "PORT"
            value = "3000"
          }

          resources {
            requests = {
              memory = "256Mi"
              cpu    = "200m"
            }
            limits = {
              memory = "512Mi"
              cpu    = "500m"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 15
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 2
          }
        }
      }
    }
  }
}

# Service LoadBalancer pour accès externe en production
resource "kubernetes_service" "app" {
  metadata {
    name      = "devsecops-app-service"
    namespace = kubernetes_namespace.production.metadata[0].name
    labels = {
      app         = "devsecops-app"
      environment = "production"
    }
  }

  spec {
    type             = "LoadBalancer"
    session_affinity = "ClientIP"

    selector = {
      app = "devsecops-app"
    }

    port {
      name        = "http"
      protocol    = "TCP"
      port        = 80
      target_port = 3000
    }
  }
}
