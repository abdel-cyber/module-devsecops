# Dépannage et FAQ

Ce document regroupe les problèmes courants et leurs solutions.

## 📋 Table des matières

- [Développement local](#développement-local)
- [Tests](#tests)
- [Docker](#docker)
- [Pipeline GitLab CI/CD](#pipeline-gitlab-cicd)
- [Terraform](#terraform)
- [AWS](#aws)
- [Azure](#azure)

## Développement local

### ❌ `npm start` : Module not found

**Problème** : `Error: Cannot find module 'express'`

**Solution** :
```bash
npm install
```

### ❌ Port 3000 déjà utilisé

**Problème** : `Error: listen EADDRINUSE: address already in use :::3000`

**Solution 1** : Changer le port
```bash
# Dans .env
PORT=3001
```

**Solution 2** : Tuer le processus
```powershell
# Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:3000 | xargs kill
```

### ❌ Cannot find module './app'

**Problème** : Le fichier `src/app.js` n'est pas trouvé

**Solution** :
1. Vérifier que `src/app.js` existe
2. Lancer depuis la racine du projet (pas depuis `src/`)
3. Vérifier la casse (Windows est insensible, Linux est sensible)

## Tests

### ❌ Tests timeout

**Problème** : `Timeout - Async callback was not invoked within the 5000 ms timeout`

**Solution** : Augmenter le timeout dans le test
```javascript
jest.setTimeout(10000); // 10 secondes
```

### ❌ Tests ne sont pas trouvés

**Problème** : `No tests found`

**Solution** :
1. Vérifier le nom du fichier : `*.test.js` ou `*.spec.js`
2. Vérifier qu'il est dans `__tests__/` ou configurer `testMatch` dans `package.json`

```json
{
  "jest": {
    "testMatch": ["**/__tests__/**/*.test.js"]
  }
}
```

### ❌ Supertest connection refused

**Problème** : `Error: connect ECONNREFUSED`

**Solution** : Ne pas démarrer le serveur avec `app.listen()` dans les tests. Exporter seulement `app` depuis `app.js`.

## Docker

### ❌ Docker daemon not running

**Problème** : `Cannot connect to the Docker daemon`

**Solution** :
1. Lancer Docker Desktop
2. Vérifier que Docker fonctionne : `docker version`

### ❌ Build échoue : npm ci failed

**Problème** : `npm ERR! The 'npm ci' command can only install with an existing package-lock.json`

**Solution** :
```bash
# Générer package-lock.json
npm install
git add package-lock.json
git commit -m "chore: add package-lock.json"
```

### ❌ Image trop volumineuse

**Problème** : Image Docker > 500 MB

**Solution** : Utiliser une image Alpine et excludre les fichiers inutiles

```dockerfile
# Utiliser Alpine (légère)
FROM node:20-alpine

# Installer seulement les dépendances de production
RUN npm ci --only=production
```

`.dockerignore` :
```
node_modules
.env
__tests__
*.log
.git
```

### ❌ Container ne démarre pas

**Problème** : `docker run` démarre puis s'arrête immédiatement

**Solution** : Vérifier les logs
```bash
docker logs <container_id>

# Ou lancer en mode interactif
docker run -it tp-devsecops-app:latest sh
```

### ❌ Permission denied lors du build

**Problème** : `COPY failed: permission denied`

**Solution** :
```bash
# Windows : Vérifier que Docker Desktop a accès au disque
# Settings → Resources → File Sharing

# Linux : Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER
newgrp docker
```

## Pipeline GitLab CI/CD

### ❌ Pipeline ne démarre pas

**Problème** : Aucun pipeline après le push

**Solution** :
1. Vérifier que `.gitlab-ci.yml` est à la racine
2. Vérifier la syntaxe YAML : https://www.yamllint.com/
3. Vérifier que les runners sont activés : **Settings → CI/CD → Runners**

### ❌ Job `test` échoue

**Problème** : Tests en erreur dans le pipeline

**Solution** :
1. Vérifier que les tests passent en local : `npm test`
2. Vérifier les logs du job dans GitLab
3. S'assurer que `npm ci` s'exécute avant `npm test`

```yaml
test:
  stage: test
  image: node:20-alpine
  before_script:
    - npm ci
  script:
    - npm test
```

### ❌ Job `security` échoue : secret détecté

**Problème** : `ERREUR : secret ou faux secret détecté (API_KEY=sk-...)`

**Solution** : Voir [docs/DEMO_SECURITY.md](DEMO_SECURITY.md)

1. Localiser le secret dans le code (voir les logs du job)
2. Remplacer par `process.env.API_KEY`
3. Configurer la variable dans GitLab CI/CD Variables
4. Commiter et pousser

### ❌ Job `build` échoue : Docker login failed

**Problème** : `Error response from daemon: login attempt failed`

**Solution** :
1. Vérifier que le Container Registry est activé : **Deploy → Container Registry**
2. Les variables `CI_REGISTRY_*` sont automatiques, pas besoin de les configurer
3. Vérifier que le runner a accès à `docker:dind`

```yaml
build:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  variables:
    DOCKER_TLS_CERTDIR: "/certs"
```

### ❌ Job `deploy_staging` ne se lance pas

**Problème** : Job skipped

**Solution** : Vérifier les conditions `rules` ou `only`

```yaml
deploy_staging:
  stage: deploy_staging
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"
```

Le job ne s'exécute que sur la branche `develop`. Vérifier :
```bash
git branch  # Branche actuelle
```

### ❌ Variables CI/CD non reconnues

**Problème** : `variable AWS_ACCESS_KEY_ID is not defined`

**Solution** :
1. Aller dans **Settings → CI/CD → Variables**
2. Vérifier que les variables sont définies
3. Décocher "Protect variable" si le job s'exécute sur une branche non protégée
4. Pour les secrets, cocher "Mask variable"

### ❌ Expired token in job

**Problème** : `Error: The security token included in the request is expired`

**Solution** : Régénérer les credentials AWS/Azure et mettre à jour les variables CI/CD.

## Terraform

### ❌ terraform init failed

**Problème** : `Error initializing the backend`

**Solution** :
```bash
# Supprimer le cache Terraform
rm -rf .terraform .terraform.lock.hcl

# Réinitialiser
terraform init
```

### ❌ Error locking state

**Problème** : `Error acquiring the state lock`

**Solution** : Un autre processus utilise le state

```bash
# AWS
terraform force-unlock <LOCK_ID>

# Ou attendre que le processus se termine
```

### ❌ Invalid credentials

**Problème** : `Error: error configuring Terraform AWS Provider: no valid credential sources`

**Solution AWS** :
```bash
# Vérifier les variables d'environnement
echo $AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY

# Ou configurer AWS CLI
aws configure
```

**Solution Azure** :
```bash
# Se connecter
az login

# Vérifier le compte
az account show

# Ou définir les variables
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
export ARM_SUBSCRIPTION_ID="..."
export ARM_TENANT_ID="..."
```

### ❌ Resource already exists

**Problème** : `Error: A resource with the ID "<ID>" already exists`

**Solution** :
```bash
# Option 1 : Importer la ressource existante
terraform import <resource_type>.<name> <id>

# Option 2 : Supprimer la ressource manuellement
# AWS Console ou Azure Portal

# Option 3 : Changer le nom dans Terraform
```

## AWS

### ❌ Unauthorized operation

**Problème** : `UnauthorizedOperation: You are not authorized to perform this operation`

**Solution** : Ajouter les permissions IAM nécessaires

Policy minimale pour le TP :
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateTags"
      ],
      "Resource": "*"
    }
  ]
}
```

### ❌ Application non accessible sur port 3000

**Problème** : `curl: (7) Failed to connect to IP:3000`

**Solution** :
1. Vérifier le Security Group :
   - Port 3000 ouvert (0.0.0.0/0)
2. SSH dans l'instance et vérifier :
   ```bash
   sudo docker ps
   sudo docker logs tp-app
   ```

### ❌ Docker pull failed dans EC2

**Problème** : `Error response from daemon: pull access denied`

**Solution** : Vérifier les credentials du registry dans le user data

```bash
# Dans le user data EC2
docker login -u ${var.registry_user} -p ${var.registry_password} ${var.registry_url}
```

## Azure

### ❌ The subscription is not registered

**Problème** : `The subscription is not registered to use namespace 'Microsoft.Web'`

**Solution** :
```bash
az provider register --namespace Microsoft.Web
az provider register --namespace Microsoft.ContainerRegistry

# Attendre quelques minutes, puis vérifier
az provider show --namespace Microsoft.Web
```

### ❌ App Service name already taken

**Problème** : `The service name is already taken`

**Solution** : Le nom d'App Service doit être globalement unique

```hcl
# Dans main.tf, utiliser un suffixe aléatoire
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_linux_web_app" "app" {
  name = "tp-devsecops-${random_string.suffix.result}"
  # ...
}
```

### ❌ Application logs not showing

**Problème** : Pas de logs dans Azure Portal

**Solution** :
```bash
# Activer les logs
az webapp log config \
  --name YOUR_APP \
  --resource-group YOUR_RG \
  --docker-container-logging filesystem

# Stream des logs
az webapp log tail \
  --name YOUR_APP \
  --resource-group YOUR_RG
```

### ❌ Container failed to start

**Problème** : `Container didn't respond to HTTP pings on port 3000`

**Solution** :
1. Vérifier que l'env var `WEBSITES_PORT=3000` est définie
2. Vérifier que le Dockerfile expose le port 3000
3. Vérifier les logs :
   ```bash
   az webapp log tail --name YOUR_APP --resource-group YOUR_RG
   ```

### ❌ Cannot pull image from registry

**Problème** : `Failed to pull image from private registry`

**Solution** : Vérifier les credentials du registry dans l'App Service

```hcl
site_config {
  application_stack {
    docker_registry_url      = var.registry_url
    docker_registry_username = var.registry_user
    docker_registry_password = var.registry_password
  }
}

app_settings = {
  "DOCKER_REGISTRY_SERVER_URL"      = var.registry_url
  "DOCKER_REGISTRY_SERVER_USERNAME" = var.registry_user
  "DOCKER_REGISTRY_SERVER_PASSWORD" = var.registry_password
}
```

## 🔍 Debugging général

### Vérifier les logs

**GitLab** :
- Build → Pipelines → Cliquer sur le pipeline → Cliquer sur le job

**Docker local** :
```bash
docker logs <container_name>
docker logs -f <container_name>  # Follow mode
```

**AWS EC2** :
```bash
# SSH dans l'instance
ssh -i key.pem ec2-user@<IP>

# Logs Docker
sudo docker logs tp-app

# Logs système
sudo journalctl -u docker
```

**Azure App Service** :
```bash
# Stream logs
az webapp log tail --name YOUR_APP --resource-group YOUR_RG

# Télécharger logs
az webapp log download --name YOUR_APP --resource-group YOUR_RG
```

### Tester en local avant de déployer

```bash
# Tests unitaires
npm test

# Serveur local
npm start
curl http://localhost:3000/health

# Docker local
docker build -t test .
docker run -p 3000:3000 --name test test
curl http://localhost:3000/health
docker logs test
```

### Valider la syntaxe

**YAML** : https://www.yamllint.com/
**Terraform** :
```bash
terraform fmt
terraform validate
```

## 📞 Besoin d'aide ?

1. Relire la documentation :
   - [README.md](../README.md)
   - [Guide de déploiement](DEPLOYMENT_GUIDE.md)
   - [Configuration GitLab](GITLAB_SETUP.md)

2. Vérifier les logs (pipeline, Docker, cloud)

3. Tester localement avant de déployer

4. Consulter la documentation officielle :
   - [GitLab CI/CD](https://docs.gitlab.com/ee/ci/)
   - [Terraform](https://www.terraform.io/docs)
   - [AWS EC2](https://docs.aws.amazon.com/ec2/)
   - [Azure App Service](https://docs.microsoft.com/azure/app-service/)
