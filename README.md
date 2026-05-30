# TP DevSecOps - Application Node.js Multi-Cloud

Application Node.js/Express pour le module DevSecOps avec pipeline CI/CD GitLab et déploiement multi-cloud (AWS/Azure).

## 🎯 Objectifs

- Développer une application Node.js/Express avec routes REST
- Implémenter des tests automatisés avec Jest et Supertest
- Conteneuriser avec Docker
- Mettre en place un pipeline GitLab CI/CD (test, security, build, deploy)
- Déployer sur AWS (staging) et Azure (production) via Terraform

## 📋 Prérequis

- Node.js 20.x (LTS)
- npm
- Docker Desktop
- Git
- Terraform
- Compte GitLab
- Compte AWS avec accès IAM
- Compte Azure avec Service Principal

## 🚀 Installation locale

1. **Cloner le repository**
   ```bash
   git clone <url-du-repo>
   cd tp-devsecops-app
   ```

2. **Installer les dépendances**
   ```bash
   npm install
   ```

3. **Configurer les variables d'environnement**
   ```bash
   cp .env.example .env
   ```

4. **Lancer l'application**
   ```bash
   npm start
   ```
   L'application sera accessible sur http://localhost:3000

## 🧪 Tests

Lancer les tests automatisés :
```bash
npm test
```

## 🐳 Docker

### Construire l'image
```bash
docker build -t tp-devsecops-app:latest .
```

### Lancer le conteneur
```bash
docker run -p 3000:3000 --name tp-app tp-devsecops-app:latest
```

### Arrêter et supprimer le conteneur
```bash
docker stop tp-app
docker rm tp-app
```

## 📡 Routes API

- `GET /` - Message de bienvenue
- `GET /health` - Health check (status + timestamp)

## 🏗️ Architecture

```
tp-devsecops-app/
├── src/
│   ├── app.js                  # Application Express
│   └── server.js               # Point d'entrée serveur
├── __tests__/
│   └── app.test.js             # Tests Jest/Supertest
├── terraform/
│   ├── aws-staging/            # Infrastructure AWS (staging)
│   │   ├── main.tf
│   │   └── README.md
│   └── azure-production/       # Infrastructure Azure (production)
│       ├── main.tf
│       └── README.md
├── docs/
│   ├── DEMO_SECURITY.md        # Guide démonstration scan de sécurité
│   ├── DEPLOYMENT_GUIDE.md     # Guide déploiement complet
│   └── GITLAB_SETUP.md         # Configuration GitLab
├── .gitlab-ci.yml              # Pipeline CI/CD
├── .env.example                # Variables d'environnement (template)
├── .gitignore
├── .dockerignore
├── Dockerfile
├── package.json
└── README.md
```

## 🔄 Pipeline CI/CD

Le pipeline GitLab comprend les stages suivants :

### Stages automatiques
1. **test** - Exécution des tests Jest
2. **security** - Scan de secrets (détection API keys, passwords)
3. **build** - Construction et push de l'image vers GitLab Container Registry

### Stages de déploiement
4. **deploy_staging** - Déploiement automatique sur AWS EC2 (branche `develop`)
5. **deploy_production** - Déploiement manuel sur Azure App Service (branche `main`)

### Workflow Git

```
feature/* → develop → main
            ↓         ↓
         AWS (auto) Azure (manual)
```

## ☁️ Environnements de déploiement

### Staging (AWS EC2)
- **Région** : eu-west-1
- **Instance** : t2.micro (Amazon Linux 2)
- **Accès** : HTTP sur port 3000
- **Déploiement** : Automatique sur push vers `develop`

### Production (Azure App Service)
- **Région** : westeurope
- **Tier** : B1 (Basic)
- **Accès** : HTTPS (certificat automatique)
- **Déploiement** : Manuel (gate) sur branche `main`

## 🔐 Sécurité

Le pipeline inclut un scan de sécurité qui détecte :
- Clés API exposées (pattern `API_KEY=sk-...`)
- Mots de passe en clair
- Autres secrets suspects

Voir [docs/DEMO_SECURITY.md](docs/DEMO_SECURITY.md) pour la démonstration complète.

## 📚 Documentation

- **[Guide de configuration GitLab](docs/GITLAB_SETUP.md)** - Configuration du projet, variables CI/CD, deploy tokens
- **[Guide de déploiement](docs/DEPLOYMENT_GUIDE.md)** - Procédures complètes de déploiement AWS/Azure
- **[Démonstration sécurité](docs/DEMO_SECURITY.md)** - Test du scan de secrets

## 🚀 Démarrage rapide

### 1. Installation et tests locaux

```bash
# Installation
npm install

# Lancer l'application
npm start

# Tester
npm test

# Docker
docker build -t tp-devsecops-app:latest .
docker run -p 3000:3000 --name tp-app tp-devsecops-app:latest
```

### 2. Configuration GitLab

```bash
# Initialiser Git
git init
git add .
git commit -m "Initial commit"

# Ajouter remote GitLab
git remote add origin https://gitlab.com/VOTRE_USER/tp-devsecops-app.git

# Pousser le code
git branch -M main
git push -u origin main

# Créer branche develop
git checkout -b develop
git push -u origin develop
```

### 3. Configurer les variables CI/CD

Dans GitLab : **Settings → CI/CD → Variables**

**AWS** :
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_DEFAULT_REGION` (ex: eu-west-1)

**Azure** :
- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`
- `ARM_SUBSCRIPTION_ID`
- `ARM_TENANT_ID`

### 4. Déclencher le pipeline

```bash
# Déploiement staging (automatique)
git checkout develop
git add .
git commit -m "feat: nouvelle fonctionnalité"
git push origin develop
# → Pipeline s'exécute → Déploiement automatique sur AWS

# Déploiement production (manuel)
git checkout main
git merge develop
git push origin main
# → Pipeline s'exécute → Cliquer "Play" sur job deploy_production dans GitLab
```

## 🧪 Validation

### Endpoints à tester

**Staging (AWS)** :
```bash
curl http://STAGING_IP:3000/
curl http://STAGING_IP:3000/health
```

**Production (Azure)** :
```bash
curl https://your-app.azurewebsites.net/
curl https://your-app.azurewebsites.net/health
```

### Réponse attendue `/health`

```json
{
  "status": "ok",
  "timestamp": "2026-02-23T14:30:00.000Z"
}
```

## 🧹 Nettoyage des ressources

Pour éviter les coûts :

```bash
# AWS
cd terraform/aws-staging
terraform destroy -auto-approve

# Azure
cd terraform/azure-production
terraform destroy -auto-approve
```

## 🐛 Dépannage

### Pipeline échoue au stage security

Le scan a détecté un secret dans le code. Voir [docs/DEMO_SECURITY.md](docs/DEMO_SECURITY.md) pour la résolution.

### Build Docker échoue

```bash
# Tester localement
docker build -t test .

# Vérifier les logs
docker build --progress=plain -t test .
```

### Déploiement AWS/Azure échoue

Vérifier :
- Les variables CI/CD dans GitLab
- Les credentials AWS/Azure
- Les logs Terraform dans les jobs GitLab

## 📞 Support

Pour les questions relatives au TP, consulter :
- [Guide de déploiement complet](docs/DEPLOYMENT_GUIDE.md)
- [FAQ et dépannage](docs/TROUBLESHOOTING.md) (à créer)

## 📊 Livrables attendus

1. ✅ Application fonctionnelle (local + Docker)
2. ✅ Tests passés (Jest/Supertest)
3. ✅ Pipeline GitLab configuré (.gitlab-ci.yml)
4. ✅ Infrastructure Terraform (AWS + Azure)
5. 📸 Captures d'écran :
   - Pipeline complet (tous stages verts)
   - Job security (échec puis succès)
   - Container Registry (images avec tags)
   - Application déployée sur AWS et Azure

## 📝 Licence

ISC
