variable "kubeconfig_path" {
  description = "Chemin vers le fichier kubeconfig pour accéder au cluster Kubernetes staging"
  type        = string
  default     = "~/.kube/config"
}

variable "docker_image" {
  description = "Image Docker à déployer (sans le tag)"
  type        = string
}

variable "docker_tag" {
  description = "Tag de l'image Docker à déployer"
  type        = string
  default     = "latest"
}

variable "registry_url" {
  description = "URL du registre Docker (GitLab Container Registry)"
  type        = string
  default     = "registry.gitlab.com"
}

variable "registry_user" {
  description = "Nom d'utilisateur pour le registre Docker"
  type        = string
  sensitive   = true
}

variable "registry_password" {
  description = "Mot de passe ou token pour le registre Docker"
  type        = string
  sensitive   = true
}

variable "registry_email" {
  description = "Email pour le registre Docker"
  type        = string
  default     = "ci@gitlab.com"
}
