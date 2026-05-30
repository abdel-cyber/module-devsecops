output "namespace" {
  description = "Nom du namespace Kubernetes créé"
  value       = kubernetes_namespace.production.metadata[0].name
}

output "deployment_name" {
  description = "Nom du deployment Kubernetes"
  value       = kubernetes_deployment.app.metadata[0].name
}

output "service_name" {
  description = "Nom du service Kubernetes"
  value       = kubernetes_service.app.metadata[0].name
}

output "replicas" {
  description = "Nombre de pods déployés"
  value       = kubernetes_deployment.app.spec[0].replicas
}

output "service_type" {
  description = "Type de service (LoadBalancer, NodePort, ClusterIP)"
  value       = kubernetes_service.app.spec[0].type
}

output "service_port" {
  description = "Port exposé par le service"
  value       = kubernetes_service.app.spec[0].port[0].port
}

output "image_deployed" {
  description = "Image Docker déployée"
  value       = "${var.docker_image}:${var.docker_tag}"
}