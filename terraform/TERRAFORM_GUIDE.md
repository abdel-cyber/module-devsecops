# Guide Terraform - Infrastructure Multi-Cloud

Ce dossier contient l'Infrastructure as Code (IaC) pour déployer l'application sur AWS (staging) et Azure (production).

## 📁 Structure

```
terraform/
├── aws-staging/         # Infrastructure AWS pour staging
│   ├── main.tf         # Configuration EC2 + Security Group
│   ├── variables.tf    # Variables d'entrée
│   ├── outputs.tf      # IP publique de l'instance
│   └── terraform.tfvars.example
└── azure-production/    # Infrastructure Azure pour production
    ├── main.tf         # Configuration App Service
    ├── variables.tf    # Variables d'entrée
    ├── outputs.tf      # URL de l'application
    └── terraform.tfvars.example
```

## 🔧 AWS Staging

### Prérequis
- Compte AWS avec accès programmé
- Credentials AWS configurés (`aws configure` ou variables d'environnement)
- GitLab Deploy Token avec permission `read_registry`

### Configuration

1. **Copier le fichier d'exemple**
   ```bash
   cd terraform/aws-staging
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Éditer terraform.tfvars**
   ```hcl
   aws_region    = "eu-west-1"
   instance_type = "t2.micro"
   docker_image  = "registry.gitlab.com/abdelmouiz99/tp-devsecops-app"
   docker_tag    = "latest"
   registry_url  = "registry.gitlab.com"
   registry_user = "DEPLOY_TOKEN_USERNAME"
   registry_password = "DEPLOY_TOKEN_PASSWORD"
   ```

3. **Déployer**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Récupérer l'IP publique**
   ```bash
   terraform output staging_public_ip
   ```

5. **Tester**
   ```bash
   curl http://$(terraform output -raw staging_public_ip)/health
   ```

### Architecture AWS
- **VPC**: VPC par défaut de la région
- **Security Group**: Ports 80 (HTTP) et 22 (SSH) ouverts
- **Instance EC2**: t2.micro Amazon Linux 2
- **User Data**: Installation Docker + pull image + lancement conteneur (port 80→3000)

---

## 🔧 Azure Production

### Prérequis
- Compte Azure avec souscription active
- Azure CLI installé et authentifié (`az login`)
- Service Principal avec droits Contributor
- GitLab Deploy Token

### Configuration

1. **Créer un Service Principal**
   ```bash
   az ad sp create-for-rbac --name "GitLab-Terraform" --role="Contributor" --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"
   ```

2. **Configurer les variables d'environnement**
   ```bash
   export ARM_CLIENT_ID="<appId>"
   export ARM_CLIENT_SECRET="<password>"
   export ARM_SUBSCRIPTION_ID="<subscription_id>"
   export ARM_TENANT_ID="<tenant>"
   ```

3. **Copier et éditer terraform.tfvars**
   ```bash
   cd terraform/azure-production
   cp terraform.tfvars.example terraform.tfvars
   ```

   ```hcl
   resource_group_name = "tp-devsecops-rg"
   azure_region        = "West Europe"
   app_name            = "tp-devsecops-prod"
   docker_image        = "registry.gitlab.com/abdelmouiz99/tp-devsecops-app"
   docker_image_tag    = "latest"
   registry_url        = "https://registry.gitlab.com"
   registry_user       = "DEPLOY_TOKEN_USERNAME"
   registry_password   = "DEPLOY_TOKEN_PASSWORD"
   ```

4. **Déployer**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. **Récupérer l'URL**
   ```bash
   terraform output production_url
   ```

### Architecture Azure
- **Resource Group**: Groupe logique pour toutes les ressources
- **App Service Plan**: Linux B1 (Basic)
- **Linux Web App**: Conteneur Docker avec image GitLab
- **Variables d'environnement**: WEBSITES_PORT=3000 pour le routage

---

## 🔐 GitLab Deploy Token

Pour que les infrastructures puissent tirer l'image Docker depuis le Container Registry privé:

1. **Aller dans GitLab**: Settings → Repository → Deploy tokens
2. **Créer un token**:
   - Name: `terraform-registry-access`
   - Scopes: ☑ `read_registry`
3. **Noter les credentials** (affichés une seule fois):
   - Username: `gitlab+deploy-token-XXXXX`
   - Token: `glpat-XXXXXXXXXXXXX`

---

## 🚀 Intégration GitLab CI/CD

Le pipeline GitLab (`.gitlab-ci.yml`) utilise automatiquement Terraform pour déployer:

- **Staging (AWS)**: Automatique sur branche `develop`
- **Production (Azure)**: Manuel (`when: manual`) sur branche `main`

Les variables `$CI_REGISTRY_*` sont injectées automatiquement par GitLab.

---

## 🧹 Nettoyage

Pour détruire l'infrastructure et éviter les coûts:

**AWS:**
```bash
cd terraform/aws-staging
terraform destroy
```

**Azure:**
```bash
cd terraform/azure-production
terraform destroy
```

---

## ❗ Troubleshooting

### AWS
- **Port 80 inaccessible**: Vérifier le Security Group
- **Docker non lancé**: Se connecter en SSH et vérifier `journalctl -u docker`
- **Registry login failed**: Vérifier le Deploy Token

### Azure
- **Image pull failed**: Vérifier l'URL du registry (avec `https://`)
- **Container not starting**: Vérifier `WEBSITES_PORT=3000`
- **Authentication error**: Vérifier les variables `ARM_*`

---

## 📚 Ressources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitLab Deploy Tokens](https://docs.gitlab.com/ee/user/project/deploy_tokens/)
