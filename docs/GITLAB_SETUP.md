# Guide de configuration GitLab CI/CD

## 🎯 Configuration du projet GitLab

### 1. Créer le projet sur GitLab

1. Aller sur https://gitlab.com
2. Cliquer sur "New project"
3. Choisir "Create blank project"
4. Nom : `tp-devsecops-app`
5. Visibilité : Private (ou Public selon vos besoins)
6. Initialiser sans README (on a déjà le code)
7. Créer le projet

### 2. Pousser le code existant

```bash
cd tp-devsecops-app

# Initialiser Git si ce n'est pas déjà fait
git init

# Ajouter tous les fichiers
git add .
git commit -m "Initial commit: Application DevSecOps complète"

# Ajouter le remote GitLab
git remote add origin https://gitlab.com/VOTRE_USERNAME/tp-devsecops-app.git

# Créer et pousser la branche main
git branch -M main
git push -u origin main

# Créer également la branche develop
git checkout -b develop
git push -u origin develop
```

### 3. Vérifier le Container Registry

1. Dans GitLab : **Deploy → Container Registry**
2. Le registry est activé automatiquement
3. URL type : `registry.gitlab.com/votre-username/tp-devsecops-app`

### 4. Créer un Deploy Token (optionnel pour déploiements manuels)

1. **Settings → Repository → Deploy tokens**
2. Nom : `deploy-token-staging`
3. Cocher :
   - ✅ `read_registry`
   - ✅ `write_registry`
4. Expiration : Définir une date (ex: 1 an)
5. Créer le token
6. ⚠️ **Copier immédiatement** le token (ne sera plus affiché)

### 5. Configurer les variables CI/CD

#### Variables pour AWS (Staging)

1. **Settings → CI/CD → Variables → Expand → Add variable**

| Key | Value | Type | Protected | Masked |
|-----|-------|------|-----------|--------|
| `AWS_ACCESS_KEY_ID` | Votre access key | Variable | ✅ | ❌ |
| `AWS_SECRET_ACCESS_KEY` | Votre secret key | Variable | ✅ | ✅ |
| `AWS_DEFAULT_REGION` | `eu-west-1` | Variable | ❌ | ❌ |

#### Variables pour Azure (Production)

| Key | Value | Type | Protected | Masked |
|-----|-------|------|-----------|--------|
| `ARM_CLIENT_ID` | Service Principal App ID | Variable | ✅ | ❌ |
| `ARM_CLIENT_SECRET` | Service Principal Password | Variable | ✅ | ✅ |
| `ARM_SUBSCRIPTION_ID` | Azure Subscription ID | Variable | ✅ | ❌ |
| `ARM_TENANT_ID` | Azure Tenant ID | Variable | ✅ | ❌ |

#### Variables de configuration

| Key | Value | Type | Protected | Masked |
|-----|-------|------|-----------|--------|
| `STAGING_URL` | (sera fourni après 1er deploy) | Variable | ❌ | ❌ |
| `PRODUCTION_URL` | (sera fourni après 1er deploy) | Variable | ✅ | ❌ |

### 6. Configuration du Runner

GitLab propose des runners partagés (Shared Runners) :

1. **Settings → CI/CD → Runners**
2. S'assurer que les "Shared runners" sont activés
3. Vérifier que le tag `docker` est disponible

Pour un runner privé (optionnel) :
```bash
# Installation du runner GitLab
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
sudo apt-get install gitlab-runner

# Enregistrement du runner
sudo gitlab-runner register
```

### 7. Activer Auto DevOps (optionnel)

1. **Settings → CI/CD → Auto DevOps**
2. Désactiver si vous utilisez votre propre `.gitlab-ci.yml`

## 🔄 Workflow Git recommandé

### Branches

- `main` : Production (déploiement manuel sur Azure)
- `develop` : Staging (déploiement automatique sur AWS)
- `feature/*` : Branches de feature (merge vers develop)

### Processus

```bash
# Créer une feature
git checkout develop
git pull origin develop
git checkout -b feature/nouvelle-fonctionnalite

# Développer et tester localement
npm test
docker build -t test .

# Commiter
git add .
git commit -m "feat: ajout nouvelle fonctionnalité"
git push origin feature/nouvelle-fonctionnalite

# Créer une Merge Request vers develop
# Dans GitLab : Merge Requests → New merge request
# Source: feature/nouvelle-fonctionnalite → Target: develop

# Une fois mergée dans develop
# → Pipeline s'exécute automatiquement
# → Tests, security, build
# → Déploiement automatique sur AWS staging

# Après validation sur staging, merger develop → main
# → Pipeline s'exécute
# → Tests, security, build
# → Déploiement MANUEL sur Azure production (cliquer le bouton dans GitLab)
```

## 📊 Surveillance du pipeline

### Vue d'ensemble

1. **Build → Pipelines** : Liste de tous les pipelines
2. Cliquer sur un pipeline pour voir les stages
3. Cliquer sur un job pour voir les logs

### Statuts

- 🟢 **Success** : Job terminé avec succès
- 🔴 **Failed** : Job en erreur (voir les logs)
- 🔵 **Running** : Job en cours d'exécution
- ⚪ **Pending** : Job en attente du runner
- ⚫ **Canceled** : Job annulé
- 🟡 **Manual** : Job nécessitant une action manuelle

### Logs importants

**Job `test`** :
```
npm ci
npm test
PASS  __tests__/app.test.js
Tests: 2 passed, 2 total
✅ Tests réussis
```

**Job `security`** :
```
✅ Aucun secret suspect détecté. Scan terminé avec succès.
```

**Job `build`** :
```
docker login -u gitlab-ci-token -p [MASKED] registry.gitlab.com
docker build -t registry.gitlab.com/user/project:abc1234 .
docker push registry.gitlab.com/user/project:abc1234
✅ Image publiée avec succès
```

## 🐛 Dépannage

### Le pipeline ne démarre pas

- Vérifier que `.gitlab-ci.yml` est présent à la racine
- Vérifier la syntaxe YAML (copier/coller dans un validateur YAML en ligne)
- Vérifier que les runners sont activés

### Job `build` échoue (Docker)

- Vérifier que le Dockerfile est valide
- Tester localement : `docker build -t test .`
- Vérifier que le runner a accès au service `docker:dind`

### Job `deploy_staging` ou `deploy_production` échoue

- Vérifier les variables AWS/Azure dans Settings → CI/CD → Variables
- Vérifier que Terraform est valide : `terraform validate`
- Vérifier les credentials AWS/Azure

### Image non visible dans Container Registry

- Vérifier les logs du job `build`
- Vérifier l'authentification : `docker login registry.gitlab.com`
- Vérifier les permissions du projet

## 📚 Ressources

- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [GitLab Container Registry](https://docs.gitlab.com/ee/user/packages/container_registry/)
- [GitLab CI/CD Variables](https://docs.gitlab.com/ee/ci/variables/)
- [GitLab Runners](https://docs.gitlab.com/runner/)

## ✅ Checklist finale

- [ ] Projet GitLab créé
- [ ] Code poussé (branches main et develop)
- [ ] Container Registry activé
- [ ] Variables CI/CD AWS configurées
- [ ] Variables CI/CD Azure configurées
- [ ] Deploy Token créé (optionnel)
- [ ] Runners activés
- [ ] Premier pipeline exécuté avec succès
- [ ] Image visible dans Container Registry
- [ ] Déploiement staging réussi
- [ ] Déploiement production testé (manuel)
