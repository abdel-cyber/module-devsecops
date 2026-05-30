# Configuration Terraform - AWS Staging

Ce dossier contient l'infrastructure as code pour l'environnement de staging sur AWS.

## 📋 Prérequis

- Terraform >= 1.0
- AWS CLI configuré avec les credentials
- Compte AWS avec droits EC2, Security Groups, VPC

## 🚀 Utilisation

### Initialisation
```bash
terraform init
```

### Planification
```bash
terraform plan \
  -var "docker_image=registry.gitlab.com/votre-groupe/tp-devsecops-app" \
  -var "docker_tag=abc1234" \
  -var "registry_url=registry.gitlab.com" \
  -var "registry_user=gitlab+deploy-token-xx" \
  -var "registry_password=votre-token"
```

### Application
```bash
terraform apply -auto-approve \
  -var "docker_image=registry.gitlab.com/votre-groupe/tp-devsecops-app" \
  -var "docker_tag=abc1234" \
  -var "registry_url=registry.gitlab.com" \
  -var "registry_user=gitlab+deploy-token-xx" \
  -var "registry_password=votre-token"
```

### Destruction
```bash
terraform destroy -auto-approve
```

## 🔧 Variables

| Variable | Description | Défaut |
|----------|-------------|--------|
| `aws_region` | Région AWS | `eu-west-1` |
| `docker_image` | Image Docker complète | - (obligatoire) |
| `docker_tag` | Tag de l'image | `latest` |
| `registry_url` | URL du registry | - (obligatoire) |
| `registry_user` | User registry | - (obligatoire) |
| `registry_password` | Password registry | - (obligatoire) |
| `instance_type` | Type EC2 | `t2.micro` |

## 📤 Outputs

- `instance_id` : ID de l'instance EC2
- `public_ip` : IP publique
- `app_url` : URL d'accès à l'application

## 🏗️ Ressources créées

- Security Group (ports 3000 et 22)
- Instance EC2 Amazon Linux 2
- User Data pour installation Docker et démarrage du conteneur

## 💡 Notes

L'instance EC2 :
- Installe Docker au démarrage
- S'authentifie au GitLab Container Registry
- Pull l'image spécifiée
- Lance le conteneur sur le port 3000
