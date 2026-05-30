# Checklist des livrables - TP DevSecOps

## 📝 Informations générales

- **Projet** : TP DevSecOps - Application Node.js Multi-Cloud
- **Date** : [À compléter]
- **Étudiant(e)** : [À compléter]
- **Groupe** : [À compléter]

---

## ✅ Partie A : Développement de l'application Node.js

- [ ] Fichier `src/app.js` créé avec Express
  - [ ] Route GET `/` retournant un JSON (message, version)
  - [ ] Route GET `/health` retournant un JSON (status, timestamp)
  - [ ] Application exportée (pas de `app.listen()` dans app.js)

- [ ] Fichier `src/server.js` créé
  - [ ] Import de `app` depuis `app.js`
  - [ ] Lecture de `process.env.PORT` avec valeur par défaut 3000
  - [ ] Démarrage du serveur avec `app.listen()`

- [ ] Fichier `package.json` configuré
  - [ ] Script `start` défini
  - [ ] Dépendance `express` installée

- [ ] Fichiers de configuration
  - [ ] `.env.example` créé avec PORT=3000
  - [ ] `.gitignore` créé (node_modules, .env, *.log)

- [ ] **Validation** :
  - [ ] `npm start` fonctionne
  - [ ] http://localhost:3000 accessible
  - [ ] http://localhost:3000/health retourne `{"status":"ok", "timestamp":"..."}`

**Captures d'écran** :
- [ ] Réponse de la route `/`
- [ ] Réponse de la route `/health`

---

## ✅ Partie B : Tests automatisés avec Jest et Supertest

- [ ] Jest et Supertest installés (`npm install --save-dev jest supertest`)

- [ ] Script `test` dans `package.json`

- [ ] Fichier `__tests__/app.test.js` créé
  - [ ] Test GET `/` - vérification status 200 et message contient "DevSecOps"
  - [ ] Test GET `/health` - vérification status 200 et status === 'ok'

- [ ] **Validation** :
  - [ ] `npm test` s'exécute sans erreur
  - [ ] Tous les tests (2/2) passent

**Captures d'écran** :
- [ ] Sortie de `npm test` montrant les 2 tests passés

**Démonstration** :
- [ ] Test échoue volontairement (modification du code)
- [ ] Test repasse après correction

---

## ✅ Partie C : Conteneurisation avec Docker

- [ ] Dockerfile créé
  - [ ] Image de base : `node:20-alpine`
  - [ ] WORKDIR `/app`
  - [ ] COPY `package*.json`
  - [ ] RUN `npm ci --only=production`
  - [ ] COPY du code source
  - [ ] EXPOSE 3000
  - [ ] ENV PORT=3000
  - [ ] CMD `["node", "src/server.js"]`

- [ ] `.dockerignore` créé
  - [ ] Exclusion : node_modules, .env, .git, *.log, __tests__

- [ ] **Validation** :
  - [ ] `docker build -t tp-devsecops-app:latest .` réussit
  - [ ] `docker run -p 3000:3000 --name tp-app tp-devsecops-app:latest` démarre
  - [ ] http://localhost:3000/health accessible depuis le conteneur
  - [ ] `docker logs tp-app` affiche le message de démarrage

**Captures d'écran** :
- [ ] Build Docker réussi
- [ ] `docker ps` montrant le conteneur actif
- [ ] Réponse `/health` depuis le conteneur

---

## ✅ Partie D + E : Pipeline GitLab CI/CD (qualité et sécurité)

- [ ] Fichier `.gitlab-ci.yml` créé à la racine

- [ ] **Stage test** configuré
  - [ ] Image : `node:20-alpine`
  - [ ] `before_script` : `npm ci`
  - [ ] `script` : `npm test`

- [ ] **Stage security** configuré
  - [ ] Image : `alpine:latest`
  - [ ] Script : grep recherchant les patterns de secrets (API_KEY=sk-...)
  - [ ] Exit 1 si secret détecté

- [ ] **Stage build** configuré
  - [ ] Image : `docker:24`
  - [ ] Service : `docker:24-dind`
  - [ ] `docker login` au GitLab Container Registry
  - [ ] Build avec 2 tags : `$CI_COMMIT_SHORT_SHA` et `latest`
  - [ ] Push des 2 tags vers le registry

- [ ] **Stages deploy** configurés (deploy_staging, deploy_production)
  - [ ] deploy_staging : automatique sur branche `develop`
  - [ ] deploy_production : manuel (`when: manual`) sur branche `main`

- [ ] **Démonstration scan de sécurité** :
  - [ ] Faux secret injecté (ex: `API_KEY="sk-demo-123456789"`)
  - [ ] Push et pipeline échoue au stage security
  - [ ] Secret supprimé, remplacé par `process.env.API_KEY`
  - [ ] Push et pipeline repasse au vert

- [ ] **Validation** :
  - [ ] Pipeline s'exécute après un push
  - [ ] Stages test, security, build passent
  - [ ] Variables CI_REGISTRY_* sont utilisées

**Captures d'écran** :
- [ ] Pipeline complet (tous stages verts)
- [ ] Job security en échec (secret détecté) + logs
- [ ] Job security en succès après correction
- [ ] Job build réussi avec push vers registry

---

## ✅ Partie F : Publication dans GitLab Container Registry

- [ ] Container Registry activé dans GitLab (Deploy → Container Registry)

- [ ] Job `build` pousse l'image vers le registry
  - [ ] Tag avec SHA du commit
  - [ ] Tag `latest`

- [ ] **Validation** :
  - [ ] Image visible dans GitLab : Deploy → Container Registry
  - [ ] Tags `$CI_COMMIT_SHORT_SHA` et `latest` présents
  - [ ] Possibilité de pull l'image : `docker pull registry.gitlab.com/.../tp-devsecops-app:latest`

**Captures d'écran** :
- [ ] Vue Container Registry avec les images et tags
- [ ] Logs du job build montrant le push réussi

---

## ✅ Partie G : Infrastructure as Code avec Terraform

### Terraform AWS (Staging)

- [ ] Dossier `terraform/aws-staging/` créé

- [ ] Fichier `main.tf` configuré
  - [ ] Provider AWS
  - [ ] Variables : docker_image, docker_tag, registry_url, registry_user, registry_password
  - [ ] Security Group (ports 3000 et 22)
  - [ ] Instance EC2 (Amazon Linux 2, type t2.micro)
  - [ ] User Data : installation Docker, login registry, pull image, run container
  - [ ] Outputs : instance_id, public_ip, app_url

- [ ] **Validation locale** :
  - [ ] `terraform init` réussit
  - [ ] `terraform validate` pas d'erreur
  - [ ] `terraform plan` affiche les ressources à créer

### Terraform Azure (Production)

- [ ] Dossier `terraform/azure-production/` créé

- [ ] Fichier `main.tf` configuré
  - [ ] Provider Azure
  - [ ] Variables : docker_image, docker_image_tag, registry_url, registry_user, registry_password
  - [ ] Resource Group
  - [ ] App Service Plan (Linux, B1)
  - [ ] Linux Web App (App Service for Containers)
  - [ ] Configuration registry et port 3000
  - [ ] Outputs : resource_group_name, app_service_name, app_url

- [ ] **Validation locale** :
  - [ ] `terraform init` réussit
  - [ ] `terraform validate` pas d'erreur
  - [ ] `terraform plan` affiche les ressources à créer

**Captures d'écran** :
- [ ] Sortie `terraform plan` AWS
- [ ] Sortie `terraform plan` Azure

---

## ✅ Partie H : Déploiement Staging (AWS)

- [ ] Variables CI/CD configurées dans GitLab
  - [ ] AWS_ACCESS_KEY_ID
  - [ ] AWS_SECRET_ACCESS_KEY
  - [ ] AWS_DEFAULT_REGION

- [ ] Job `deploy_staging` dans `.gitlab-ci.yml`
  - [ ] S'exécute sur branche `develop`
  - [ ] `terraform init` et `terraform apply`
  - [ ] Variables passées : docker_image, docker_tag, registry_*

- [ ] **Validation** :
  - [ ] Push sur branche `develop`
  - [ ] Pipeline s'exécute et déploie automatiquement
  - [ ] Instance EC2 visible dans AWS Console
  - [ ] Application accessible : http://IP_PUBLIC:3000/health
  - [ ] Réponse `{"status":"ok", "timestamp":"..."}`

**Captures d'écran** :
- [ ] Job `deploy_staging` réussi (logs)
- [ ] AWS Console : instance EC2 active
- [ ] Réponse de l'application sur AWS (curl ou navigateur)
- [ ] Output Terraform avec l'URL

---

## ✅ Partie I : Déploiement Production (Azure)

- [ ] Service Principal Azure créé

- [ ] Variables CI/CD configurées dans GitLab
  - [ ] ARM_CLIENT_ID
  - [ ] ARM_CLIENT_SECRET
  - [ ] ARM_SUBSCRIPTION_ID
  - [ ] ARM_TENANT_ID

- [ ] Job `deploy_production` dans `.gitlab-ci.yml`
  - [ ] S'exécute sur branche `main`
  - [ ] `when: manual` (gate)
  - [ ] `terraform init` et `terraform apply`
  - [ ] Variables passées : docker_image, docker_image_tag, registry_*

- [ ] **Validation** :
  - [ ] Merge `develop` → `main` et push
  - [ ] Pipeline s'exécute (test, security, build passent)
  - [ ] Job `deploy_production` en attente (manual)
  - [ ] Clic sur "Play" pour déclencher le déploiement
  - [ ] Job réussit
  - [ ] App Service visible dans Azure Portal
  - [ ] Application accessible : https://app-tp-devsecops-xxxx.azurewebsites.net/health
  - [ ] HTTPS actif automatiquement
  - [ ] Réponse `{"status":"ok", "timestamp":"..."}`

**Captures d'écran** :
- [ ] Job `deploy_production` en attente (manual)
- [ ] Job `deploy_production` réussi après déclenchement
- [ ] Azure Portal : App Service actif
- [ ] Réponse de l'application sur Azure (HTTPS)
- [ ] Output Terraform avec l'URL

---

## ✅ Chaîne complète : GitLab → Registry → AWS/Azure

- [ ] **Flux complet validé** :
  1. Code poussé vers GitLab
  2. Pipeline CI exécute tests et security
  3. Image Docker buildée et poussée dans GitLab Container Registry
  4. Terraform (AWS) récupère l'image depuis le registry et la déploie sur EC2
  5. Terraform (Azure) récupère l'image depuis le registry et la déploie sur App Service
  6. Application accessible en staging (AWS) et production (Azure)

- [ ] **Traçabilité** :
  - [ ] Chaque commit a une image taguée avec son SHA
  - [ ] Tag `latest` pointe vers la dernière version
  - [ ] Logs GitLab permettent de tracer le déploiement

**Diagramme** :
```
Developer → GitLab (code) → Pipeline CI → Container Registry
                                               ↓
                              ┌────────────────┴────────────────┐
                              ↓                                  ↓
                         AWS EC2 (staging)              Azure App Service (production)
```

---

## 📚 Documentation et livrables

- [ ] README.md complet
  - [ ] Description du projet
  - [ ] Prérequis
  - [ ] Installation locale
  - [ ] Commandes Docker
  - [ ] Architecture
  - [ ] Pipeline CI/CD
  - [ ] Environnements

- [ ] Fichiers de documentation dans `docs/`
  - [ ] GITLAB_SETUP.md (configuration GitLab)
  - [ ] DEPLOYMENT_GUIDE.md (guide déploiement complet)
  - [ ] DEMO_SECURITY.md (démonstration scan sécurité)
  - [ ] TROUBLESHOOTING.md (dépannage)
  - [ ] COMMANDS_CHEATSHEET.md (commandes utiles)

- [ ] Terraform README
  - [ ] terraform/aws-staging/README.md
  - [ ] terraform/azure-production/README.md

- [ ] Fichiers de configuration
  - [ ] .gitlab-ci.yml commenté
  - [ ] Dockerfile commenté
  - [ ] Terraform bien structuré et commenté

---

## 📸 Dossier de captures d'écran

Organiser les captures dans un dossier `screenshots/` ou un document :

1. **Développement local**
   - [ ] Route `/` 
   - [ ] Route `/health`

2. **Tests**
   - [ ] `npm test` réussi

3. **Docker**
   - [ ] Build réussi
   - [ ] Container en cours d'exécution
   - [ ] Réponse de l'application containerisée

4. **Pipeline GitLab**
   - [ ] Vue d'ensemble du pipeline (stages)
   - [ ] Job test réussi
   - [ ] Job security en échec (secret détecté)
   - [ ] Job security réussi (après correction)
   - [ ] Job build réussi
   - [ ] Job deploy_staging réussi
   - [ ] Job deploy_production (manual, puis réussi)

5. **Container Registry**
   - [ ] Images avec tags (SHA + latest)

6. **AWS**
   - [ ] Instance EC2 dans la console
   - [ ] Réponse de l'application sur AWS

7. **Azure**
   - [ ] App Service dans le portail
   - [ ] Réponse de l'application sur Azure (HTTPS)

8. **Diagramme**
   - [ ] Architecture globale (optionnel mais recommandé)

---

## 🎓 Éléments d'évaluation

### Critères techniques (70%)

- [ ] **Application (15%)** : Fonctionne localement, routes correctes, code propre
- [ ] **Tests (10%)** : Tests passent, couverture suffisante
- [ ] **Docker (10%)** : Image optimisée, fonctionne correctement
- [ ] **Pipeline CI/CD (20%)** : Tous les stages fonctionnent, bien configuré
- [ ] **Terraform (15%)** : Infrastructure correctement définie, déploiements réussis

### Documentation et présentation (20%)

- [ ] README clair et complet
- [ ] Code commenté
- [ ] Documentation technique présente
- [ ] Captures d'écran pertinentes

### Démonstrations (10%)

- [ ] Scan de sécurité (échec → correction → succès)
- [ ] Chaîne complète de déploiement
- [ ] Rollback ou mise à jour

---

## 🧹 Nettoyage des ressources (IMPORTANT)

Après la correction du TP, détruire les ressources cloud pour éviter les frais :

```bash
# AWS
cd terraform/aws-staging
terraform destroy -auto-approve

# Azure
cd terraform/azure-production
terraform destroy -auto-approve
```

- [ ] Ressources AWS détruites
- [ ] Ressources Azure détruites
- [ ] Vérification dans les consoles (aucune ressource active)

---

## 📅 Dates importantes

- **Date de rendu** : [À compléter]
- **Date de présentation** : [À compléter]
- **Format de rendu** : [Lien GitLab + archive ZIP + PDF]

---

## ✍️ Notes supplémentaires

[Espace pour vos notes, difficultés rencontrées, améliorations apportées, etc.]

---

**Signature** : ___________________  
**Date** : ___________________
