# Configuration Terraform - Azure Production

Ce dossier contient l'infrastructure as code pour l'environnement de production sur Azure.

## 📋 Prérequis

- Terraform >= 1.0
- Azure CLI installé et authentifié
- Service Principal Azure avec les droits nécessaires
- Abonnement Azure actif

## 🔐 Configuration Service Principal

Créer un Service Principal :
```bash
az ad sp create-for-rbac --name "sp-tp-devsecops" --role Contributor
```

Exporter les variables d'environnement :
```bash
export ARM_CLIENT_ID="<appId>"
export ARM_CLIENT_SECRET="<password>"
export ARM_SUBSCRIPTION_ID="<subscriptionId>"
export ARM_TENANT_ID="<tenant>"
```

## 🚀 Utilisation

### Initialisation
```bash
terraform init
```

### Planification
```bash
terraform plan \
  -var "docker_image=registry.gitlab.com/votre-groupe/tp-devsecops-app" \
  -var "docker_image_tag=latest" \
  -var "registry_url=https://registry.gitlab.com" \
  -var "registry_user=gitlab+deploy-token-xx" \
  -var "registry_password=votre-token"
```

### Application
```bash
terraform apply -auto-approve \
  -var "docker_image=registry.gitlab.com/votre-groupe/tp-devsecops-app" \
  -var "docker_image_tag=latest" \
  -var "registry_url=https://registry.gitlab.com" \
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
| `azure_location` | Région Azure | `westeurope` |
| `docker_image` | Image Docker complète | - (obligatoire) |
| `docker_image_tag` | Tag de l'image | `latest` |
| `registry_url` | URL du registry (avec https://) | - (obligatoire) |
| `registry_user` | User registry | - (obligatoire) |
| `registry_password` | Password registry | - (obligatoire) |

## 📤 Outputs

- `resource_group_name` : Nom du Resource Group
- `app_service_name` : Nom de l'App Service
- `app_url` : URL de l'application
- `default_hostname` : Hostname Azure

## 🏗️ Ressources créées

- Resource Group
- App Service Plan (Linux, B1)
- Linux Web App (App Service for Containers)
- Configuration Docker avec authentification au registry

## 💡 Notes

L'App Service :
- Utilise un plan Linux B1 (adapté au TP)
- Configure automatiquement le port 3000
- S'authentifie au GitLab Container Registry
- Pull automatiquement l'image au démarrage
- Supporte HTTPS uniquement (https_only = true)
- Nom unique généré avec suffixe aléatoire
