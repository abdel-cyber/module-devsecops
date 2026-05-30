# Exemples de commandes utiles

## 📦 NPM

```bash
# Installation
npm install                    # Installer toutes les dépendances
npm ci                         # Installation propre (utilise package-lock.json)
npm install --only=production  # Seulement les dépendances de production

# Scripts
npm start                      # Lancer l'application
npm test                       # Lancer les tests
npm test -- --watch            # Tests en mode watch
npm test -- --coverage         # Tests avec couverture

# Autres
npm audit                      # Vérifier les vulnérabilités
npm audit fix                  # Corriger les vulnérabilités
npm outdated                   # Vérifier les packages obsolètes
npm update                     # Mettre à jour les packages
```

## 🐳 Docker

```bash
# Build
docker build -t tp-devsecops-app:latest .
docker build -t tp-devsecops-app:v1.0 .
docker build --no-cache -t tp-devsecops-app:latest .  # Sans cache

# Run
docker run -p 3000:3000 --name tp-app tp-devsecops-app:latest
docker run -d -p 3000:3000 --name tp-app tp-devsecops-app:latest  # Détaché
docker run -it --rm -p 3000:3000 tp-devsecops-app:latest          # Interactif + auto-remove

# Avec variables d'environnement
docker run -p 3000:3000 -e PORT=3000 -e NODE_ENV=production --name tp-app tp-devsecops-app:latest

# Avec fichier .env
docker run -p 3000:3000 --env-file .env --name tp-app tp-devsecops-app:latest

# Gestion des conteneurs
docker ps                      # Conteneurs actifs
docker ps -a                   # Tous les conteneurs
docker stop tp-app             # Arrêter
docker start tp-app            # Démarrer
docker restart tp-app          # Redémarrer
docker rm tp-app               # Supprimer
docker rm -f tp-app            # Forcer la suppression

# Logs et debug
docker logs tp-app             # Afficher les logs
docker logs -f tp-app          # Suivre les logs
docker logs --tail 50 tp-app   # 50 dernières lignes
docker exec -it tp-app sh      # Shell interactif

# Images
docker images                  # Lister les images
docker rmi tp-devsecops-app:latest  # Supprimer une image
docker image prune             # Nettoyer les images non utilisées
docker system prune -a         # Nettoyage complet

# Registry (GitLab)
docker login registry.gitlab.com
docker tag tp-devsecops-app:latest registry.gitlab.com/user/project:latest
docker push registry.gitlab.com/user/project:latest
docker pull registry.gitlab.com/user/project:latest
```

## 🔨 Git

```bash
# Configuration initiale
git init
git config user.name "Votre Nom"
git config user.email "votre@email.com"

# Branches
git branch                     # Lister les branches
git branch -a                  # Toutes les branches (locales + distantes)
git checkout -b develop        # Créer et basculer sur develop
git checkout main              # Basculer sur main
git merge develop              # Merger develop dans la branche actuelle

# Commits
git status                     # Statut des fichiers
git add .                      # Ajouter tous les fichiers
git add src/app.js             # Ajouter un fichier spécifique
git commit -m "feat: message"  # Commiter
git commit --amend             # Modifier le dernier commit

# Remote
git remote add origin https://gitlab.com/user/project.git
git remote -v                  # Voir les remotes
git push -u origin main        # Push et set upstream
git push origin develop        # Push vers develop
git pull origin main           # Pull depuis main

# Historique
git log                        # Historique des commits
git log --oneline              # Historique compact
git log --graph --oneline      # Graphique
git show <commit_hash>         # Détails d'un commit

# Annuler des changements
git checkout -- file.js        # Annuler les modifications d'un fichier
git reset HEAD file.js         # Unstage un fichier
git reset --hard HEAD          # Annuler tous les changements (DANGER)
git revert <commit_hash>       # Créer un commit qui annule un commit

# Tags
git tag v1.0.0                 # Créer un tag
git push origin v1.0.0         # Pousser un tag
git tag -d v1.0.0              # Supprimer un tag local
```

## 🏗️ Terraform

```bash
# Initialisation
terraform init                 # Initialiser le projet
terraform init -upgrade        # Mettre à jour les providers

# Validation et formatage
terraform fmt                  # Formater le code
terraform validate             # Valider la syntaxe

# Planification
terraform plan                 # Voir les changements
terraform plan -out=tfplan     # Sauvegarder le plan

# Application
terraform apply                # Appliquer les changements (avec confirmation)
terraform apply -auto-approve  # Appliquer sans confirmation
terraform apply tfplan         # Appliquer un plan sauvegardé

# Avec variables
terraform apply -var="docker_tag=abc123" -var="aws_region=eu-west-1"
terraform apply -var-file="prod.tfvars"

# Destruction
terraform destroy              # Détruire l'infrastructure (avec confirmation)
terraform destroy -auto-approve # Détruire sans confirmation

# Inspection
terraform show                 # État actuel
terraform output               # Voir les outputs
terraform output -json         # Outputs en JSON
terraform output app_url       # Output spécifique

# État (state)
terraform state list           # Lister les ressources
terraform state show <resource> # Détails d'une ressource
terraform refresh              # Rafraîchir l'état

# Import
terraform import aws_instance.app i-1234567890abcdef0

# Workspace (environnements)
terraform workspace list       # Lister les workspaces
terraform workspace new staging # Créer un workspace
terraform workspace select staging # Sélectionner un workspace
```

## ☁️ AWS CLI

```bash
# Configuration
aws configure                  # Configuration interactive
aws configure list             # Voir la configuration

# EC2
aws ec2 describe-instances     # Lister les instances
aws ec2 describe-instances --filters "Name=tag:Name,Values=tp-devsecops-staging"
aws ec2 start-instances --instance-ids i-1234567890
aws ec2 stop-instances --instance-ids i-1234567890
aws ec2 terminate-instances --instance-ids i-1234567890

# Security Groups
aws ec2 describe-security-groups
aws ec2 authorize-security-group-ingress --group-id sg-123456 --protocol tcp --port 3000 --cidr 0.0.0.0/0

# Logs (CloudWatch)
aws logs tail /aws/ec2/app --follow

# S3 (pour Terraform state backend)
aws s3 ls                      # Lister les buckets
aws s3 mb s3://terraform-state-bucket # Créer un bucket
```

## ☁️ Azure CLI

```bash
# Connexion
az login                       # Se connecter
az account show                # Voir le compte actuel
az account list                # Lister les comptes
az account set --subscription <id> # Changer d'abonnement

# Resource Groups
az group list                  # Lister les resource groups
az group create --name rg-test --location westeurope
az group delete --name rg-test --yes

# App Service
az webapp list                 # Lister les web apps
az webapp show --name YOUR_APP --resource-group YOUR_RG
az webapp start --name YOUR_APP --resource-group YOUR_RG
az webapp stop --name YOUR_APP --resource-group YOUR_RG
az webapp restart --name YOUR_APP --resource-group YOUR_RG
az webapp delete --name YOUR_APP --resource-group YOUR_RG

# Logs
az webapp log config --name YOUR_APP --resource-group YOUR_RG --docker-container-logging filesystem
az webapp log tail --name YOUR_APP --resource-group YOUR_RG
az webapp log download --name YOUR_APP --resource-group YOUR_RG

# Service Principal (pour Terraform)
az ad sp create-for-rbac --name "sp-terraform" --role Contributor
```

## 🧪 Curl (tests)

```bash
# GET simple
curl http://localhost:3000
curl http://localhost:3000/health

# Avec headers
curl -H "Accept: application/json" http://localhost:3000

# Verbose (debug)
curl -v http://localhost:3000

# Suivre les redirections
curl -L http://localhost:3000

# HTTPS (ignorer certificat)
curl -k https://localhost:3000

# Mesurer le temps
curl -w "\nTime: %{time_total}s\n" http://localhost:3000

# Formater le JSON
curl http://localhost:3000 | jq

# POST avec données JSON
curl -X POST http://localhost:3000/api \
  -H "Content-Type: application/json" \
  -d '{"key":"value"}'

# Sauvegarder la réponse
curl http://localhost:3000 -o response.json
```

## 🔍 Monitoring

```bash
# Tester la disponibilité (boucle)
while true; do curl -s http://localhost:3000/health | jq; sleep 5; done

# Watch Terraform output
watch -n 5 terraform output

# Watch Docker logs
docker logs -f tp-app

# Watch Azure logs
az webapp log tail --name YOUR_APP --resource-group YOUR_RG

# Ping continu
ping -c 100 YOUR_IP
```

## 🧹 Nettoyage

```bash
# Docker cleanup
docker stop $(docker ps -aq)   # Arrêter tous les conteneurs
docker rm $(docker ps -aq)     # Supprimer tous les conteneurs
docker rmi $(docker images -q) # Supprimer toutes les images
docker system prune -a --volumes # Nettoyage complet

# Node modules
rm -rf node_modules package-lock.json
npm install

# Terraform
rm -rf .terraform .terraform.lock.hcl terraform.tfstate*

# Git
git clean -fd                  # Supprimer les fichiers non trackés
```
