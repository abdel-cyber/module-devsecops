variable "aws_region" {
  type        = string
  default     = "eu-west-1"
  description = "Région AWS"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "docker_image" {
  type        = string
  description = "URL complète de l'image (ex. registry.gitlab.com/groupe/tp-devsecops-app)"
}

variable "docker_tag" {
  type    = string
  default = "latest"
}

variable "registry_url" {
  type        = string
  description = "URL du registry (ex. registry.gitlab.com)"
}

variable "registry_user" {
  type        = string
  description = "Utilisateur pour docker login (ex. GitLab Deploy Token)"
  sensitive   = true
}

variable "registry_password" {
  type        = string
  description = "Mot de passe / token pour docker login"
  sensitive   = true
}
