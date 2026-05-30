output "namespace" {
  description = "Nom du namespace Kubernetes créé"
  value       = "tp-devsecops-staging"
}

output "deployment_name" {
  description = "Nom du deployment Kubernetes"
  value       = "devsecops-app"
}

output "service_name" {
  description = "Nom du service Kubernetes"
  value       = "devsecops-app-service"
}

output "replicas" {
  description = "Nombre de pods déployés"
  value       = "3"
}

output "service_type" {
  description = "Type de service (LoadBalancer, NodePort, ClusterIP)"
  value       = "LoadBalancer"
}

output "service_port" {
  description = "Port exposé par le service"
  value       = 80
}

output "image_deployed" {
  description = "Image Docker déployée"
  value       = "${var.docker_image}:${var.docker_tag}"
}
