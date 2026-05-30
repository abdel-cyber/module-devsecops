# Guide de déploiement complet

Ce document décrit les étapes pour déployer l'application du développement local jusqu'à la production Azure.

## 📋 Table des matières

1. [Prérequis](#prérequis)
2. [Configuration initiale](#configuration-initiale)
3. [Développement local](#développement-local)
4. [GitLab CI/CD](#gitlab-cicd)
5. [Déploiement Staging (AWS)](#déploiement-staging-aws)
6. [Déploiement Production (Azure)](#déploiement-production-azure)
7. [Vérification et tests](#vérification-et-tests)
8. [Rollback](#rollback)
9. [Monitoring](#monitoring)

## Prérequis

### Outils requis

- [x] Node.js 20.x LTS
- [x] npm
- [x] Docker Desktop
- [x] Git
- [x] Terraform 1.0+
- [x] AWS CLI (optionnel)
- [x] Azure CLI (optionnel)

### Comptes requis

- [x] GitLab.com (gratuit)
- [x] AWS Account avec IAM User
- [x] Azure Account avec Service Principal

## Configuration initiale

### 1. Cloner et configurer le projet

```bash
# Cloner le repository
git clone https://gitlab.com/VOTRE_USERNAME/tp-devsecops-app.git
cd tp-devsecops-app

# Installer les dépendances
npm install

# Créer le fichier .env
cp .env.example .env
```

### 2. Configuration AWS

```bash
# Configurer AWS CLI (optionnel)
aws configure
# AWS Access Key ID: VOTRE_ACCESS_KEY
# AWS Secret Access Key: VOTRE_SECRET_KEY
# Default region name: eu-west-1
# Default output format: json
```

Dans GitLab (Settings → CI/CD → Variables) :
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_DEFAULT_REGION`

### 3. Configuration Azure

```bash
# Se connecter à Azure
az login

# Créer un Service Principal
az ad sp create-for-rbac --name "sp-tp-devsecops" --role Contributor --scopes /subscriptions/YOUR_SUBSCRIPTION_ID

# Noter les valeurs retournées :
# - appId (ARM_CLIENT_ID)
# - password (ARM_CLIENT_SECRET)
# - tenant (ARM_TENANT_ID)
```

Dans GitLab (Settings → CI/CD → Variables) :
- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`
- `ARM_SUBSCRIPTION_ID`
- `ARM_TENANT_ID`

## Développement local

### Lancer l'application

```bash
npm start
```

Accéder à :
- http://localhost:3000 - Page d'accueil
- http://localhost:3000/health - Health check

### Exécuter les tests

```bash
npm test
```

Résultat attendu :
```
PASS  __tests__/app.test.js
  Routes
    ✓ GET / retourne un message (44 ms)
    ✓ GET /health retourne status ok (6 ms)

Tests: 2 passed, 2 total
```

### Tester avec Docker

```bash
# Build
docker build -t tp-devsecops-app:latest .

# Run
docker run -p 3000:3000 --name tp-app tp-devsecops-app:latest

# Test
curl http://localhost:3000/health

# Stop et cleanup
docker stop tp-app
docker rm tp-app
```

## GitLab CI/CD

### Workflow des branches

```
feature/xyz → develop → main
    ↓           ↓        ↓
    MR        AWS     Azure
              Auto    Manual
```

### Pipeline stages

1. **test** : Tests Jest
2. **security** : Scan de secrets
3. **build** : Build et push Docker image
4. **deploy_staging** : Déploiement automatique sur AWS (branche develop)
5. **deploy_production** : Déploiement manuel sur Azure (branche main)

### Déclencher un déploiement

#### Vers Staging (AWS) - Automatique

```bash
git checkout develop
git pull origin develop

# Faire des modifications
git add .
git commit -m "feat: nouvelle fonctionnalité"
git push origin develop
```

→ Pipeline démarre automatiquement
→ Si tous les stages passent, déploiement sur AWS

#### Vers Production (Azure) - Manuel

```bash
git checkout main
git pull origin main
git merge develop
git push origin main
```

→ Pipeline démarre automatiquement
→ Stages test, security, build s'exécutent
→ **Action manuelle requise** : Aller dans GitLab → Build → Pipelines → Cliquer sur le bouton "Play" du job `deploy_production`

## Déploiement Staging (AWS)

### Architecture

```
Internet → AWS EC2 (eu-west-1)
           ├── Security Group (3000, 22)
           ├── Docker Engine
           └── Container (tp-devsecops-app:SHA)
```

### Déploiement manuel (test local)

```bash
cd terraform/aws-staging

# Initialiser Terraform
terraform init

# Planifier
terraform plan \
  -var "docker_image=registry.gitlab.com/YOUR_USER/tp-devsecops-app" \
  -var "docker_tag=latest" \
  -var "registry_url=registry.gitlab.com" \
  -var "registry_user=YOUR_GITLAB_USER" \
  -var "registry_password=YOUR_GITLAB_TOKEN"

# Appliquer
terraform apply -auto-approve \
  -var "docker_image=registry.gitlab.com/YOUR_USER/tp-devsecops-app" \
  -var "docker_tag=latest" \
  -var "registry_url=registry.gitlab.com" \
  -var "registry_user=YOUR_GITLAB_USER" \
  -var "registry_password=YOUR_GITLAB_TOKEN"

# Récupérer l'URL
terraform output app_url
```

### Accès à l'application

```bash
# Récupérer l'IP publique
export STAGING_IP=$(terraform output -raw public_ip)

# Tester
curl http://$STAGING_IP:3000/health
```

### SSH dans l'instance (debug)

```bash
# Récupérer l'IP
export STAGING_IP=$(terraform output -raw public_ip)

# Se connecter (nécessite une key pair configurée)
ssh -i your-key.pem ec2-user@$STAGING_IP

# Vérifier Docker
sudo docker ps
sudo docker logs tp-app
```

## Déploiement Production (Azure)

### Architecture

```
Internet (HTTPS) → Azure App Service (westeurope)
                   ├── App Service Plan (B1)
                   ├── Container Registry Auth
                   └── Container (tp-devsecops-app:latest)
```

### Déploiement manuel (test local)

```bash
cd terraform/azure-production

# Se connecter à Azure
az login

# Initialiser Terraform
terraform init

# Planifier
terraform plan \
  -var "docker_image=registry.gitlab.com/YOUR_USER/tp-devsecops-app" \
  -var "docker_image_tag=latest" \
  -var "registry_url=https://registry.gitlab.com" \
  -var "registry_user=YOUR_GITLAB_USER" \
  -var "registry_password=YOUR_GITLAB_TOKEN"

# Appliquer
terraform apply -auto-approve \
  -var "docker_image=registry.gitlab.com/YOUR_USER/tp-devsecops-app" \
  -var "docker_image_tag=latest" \
  -var "registry_url=https://registry.gitlab.com" \
  -var "registry_user=YOUR_GITLAB_USER" \
  -var "registry_password=YOUR_GITLAB_TOKEN"

# Récupérer l'URL
terraform output app_url
```

### Accès à l'application

```bash
# Récupérer l'URL
export PROD_URL=$(terraform output -raw app_url)

# Tester (HTTPS automatique)
curl $PROD_URL/health
```

### Surveillance Azure

```bash
# Logs en temps réel
az webapp log tail --name YOUR_APP_NAME --resource-group rg-tp-devsecops-production

# Redémarrer l'app
az webapp restart --name YOUR_APP_NAME --resource-group rg-tp-devsecops-production
```

## Vérification et tests

### Checklist post-déploiement

#### Staging (AWS)

- [ ] Pipeline `deploy_staging` terminé avec succès
- [ ] Instance EC2 visible dans AWS Console
- [ ] `curl http://STAGING_IP:3000/health` retourne `{"status":"ok"}`
- [ ] Logs Docker accessibles : `docker logs tp-app`

#### Production (Azure)

- [ ] Pipeline `deploy_production` terminé avec succès
- [ ] App Service visible dans Azure Portal
- [ ] `curl https://PROD_URL/health` retourne `{"status":"ok"}`
- [ ] Certificate HTTPS valide
- [ ] Logs Azure accessibles

### Tests fonctionnels

```bash
# Health check
curl https://your-app.azurewebsites.net/health

# Page d'accueil
curl https://your-app.azurewebsites.net/

# Vérifier le JSON
curl -H "Accept: application/json" https://your-app.azurewebsites.net/
```

## Rollback

### Rollback sur AWS (Staging)

```bash
cd terraform/aws-staging

# Option 1 : Redéployer une ancienne image
terraform apply -auto-approve \
  -var "docker_tag=ANCIEN_SHA"

# Option 2 : Détruire et recréer
terraform destroy -auto-approve
terraform apply -auto-approve
```

### Rollback sur Azure (Production)

```bash
cd terraform/azure-production

# Option 1 : Redéployer une ancienne image
terraform apply -auto-approve \
  -var "docker_image_tag=ANCIEN_TAG"

# Option 2 : Via Azure CLI
az webapp config container set \
  --name YOUR_APP_NAME \
  --resource-group rg-tp-devsecops-production \
  --docker-custom-image-name registry.gitlab.com/USER/PROJECT:OLD_TAG
```

### Rollback via GitLab

1. Aller dans **Build → Pipelines**
2. Trouver un ancien pipeline qui fonctionnait
3. Cliquer sur "Retry" pour le job de déploiement
4. Ou créer un nouveau commit avec le code précédent

## Monitoring

### GitLab Container Registry

```
Deploy → Container Registry
```

Vérifier :
- Présence des tags (SHA + latest)
- Taille des images
- Date de push

### AWS CloudWatch (Staging)

```bash
# Via AWS CLI
aws ec2 describe-instances --filters "Name=tag:Name,Values=tp-devsecops-staging"

# Logs système (nécessite CloudWatch Agent configuré)
aws logs tail /aws/ec2/tp-devsecops-staging --follow
```

### Azure Monitor (Production)

```bash
# Métriques
az monitor metrics list --resource YOUR_APP_ID --metric "Requests"

# Logs en temps réel
az webapp log tail --name YOUR_APP_NAME --resource-group rg-tp-devsecops-production

# Logs HTTP
az webapp log download --name YOUR_APP_NAME --resource-group rg-tp-devsecops-production
```

### Endpoints de monitoring

- **Staging** : http://STAGING_IP:3000/health
- **Production** : https://PROD_URL/health

Format de réponse :
```json
{
  "status": "ok",
  "timestamp": "2026-02-23T14:30:00.000Z"
}
```

## 🧹 Nettoyage des ressources

### AWS

```bash
cd terraform/aws-staging
terraform destroy -auto-approve
```

### Azure

```bash
cd terraform/azure-production
terraform destroy -auto-approve
```

### Container Registry

Images nettoyées automatiquement selon la politique de rétention, ou manuellement dans GitLab : **Deploy → Container Registry → Delete**

## 📞 Support et dépannage

Voir [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md) pour les problèmes courants et solutions.
