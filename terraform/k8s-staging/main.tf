terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

# Provider kubectl - Utilise le kubeconfig pour se connecter au cluster staging
provider "kubectl" {
  config_path = var.kubeconfig_path
}

# Préparation de la configuration Docker pour le secret
locals {
  docker_config_json = base64encode(jsonencode({
    auths = {
      "${var.registry_url}" = {
        username = var.registry_user
        password = var.registry_password
        email    = var.registry_email
        auth     = base64encode("${var.registry_user}:${var.registry_password}")
      }
    }
  }))
}

# Apply Namespace
resource "kubectl_manifest" "namespace" {
  yaml_body = file("${path.module}/manifests/namespace.yaml")
}

# Apply Secret avec substitution de variables
resource "kubectl_manifest" "secret" {
  depends_on = [kubectl_manifest.namespace]
  
  yaml_body = templatefile("${path.module}/manifests/secret.yaml", {
    docker_config_json = local.docker_config_json
  })
}

# Apply Deployment avec substitution de variables
resource "kubectl_manifest" "deployment" {
  depends_on = [kubectl_manifest.secret]
  
  yaml_body = templatefile("${path.module}/manifests/deployment.yaml", {
    docker_image = var.docker_image
    docker_tag   = var.docker_tag
  })
}

# Apply Service
resource "kubectl_manifest" "service" {
  depends_on = [kubectl_manifest.deployment]
  
  yaml_body = file("${path.module}/manifests/service.yaml")
}
