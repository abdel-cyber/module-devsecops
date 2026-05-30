# 🚀 Guide : Pousser le projet vers GitLab

## ✅ État actuel du repository local

- ✅ Git initialisé
- ✅ 22 fichiers commités
- ✅ Branche `main` créée
- ✅ Branche `develop` créée (active actuellement)

## 📝 Étapes pour pousser vers GitLab

### 1️⃣ Créer le projet sur GitLab

1. Aller sur **https://gitlab.com**
2. Se connecter avec votre compte
3. Cliquer sur **"New project"** (ou **"Nouveau projet"**)
4. Choisir **"Create blank project"** (**"Créer un projet vierge"**)
5. Configuration du projet :
   - **Nom du projet** : `tp-devsecops-app`
   - **Visibilité** : Private (ou Public selon votre préférence)
   - ⚠️ **DÉCOCHER** "Initialize repository with a README" (on a déjà notre code)
   - ⚠️ **DÉCOCHER** ".gitignore" et "CI/CD configuration" (on a déjà tout)
6. Cliquer sur **"Create project"**

### 2️⃣ Récupérer l'URL du projet GitLab

Après la création du projet, GitLab affiche une page avec l'URL du repository.

**Format de l'URL** :
```
https://gitlab.com/VOTRE_USERNAME/tp-devsecops-app.git
```

**Exemple** :
```
https://gitlab.com/john-doe/tp-devsecops-app.git
```

### 3️⃣ Ajouter le remote GitLab

Dans PowerShell (depuis le dossier du projet) :

```powershell
# Remplacer VOTRE_USERNAME par votre nom d'utilisateur GitLab
git remote add origin https://gitlab.com/VOTRE_USERNAME/tp-devsecops-app.git

# Vérifier que le remote est ajouté
git remote -v
```

**Résultat attendu** :
```
origin  https://gitlab.com/VOTRE_USERNAME/tp-devsecops-app.git (fetch)
origin  https://gitlab.com/VOTRE_USERNAME/tp-devsecops-app.git (push)
```

### 4️⃣ Pousser les branches vers GitLab

```powershell
# Pousser la branche main
git push -u origin main

# Pousser la branche develop
git push -u origin develop
```

**Note** : GitLab va vous demander vos identifiants :
- **Username** : Votre nom d'utilisateur GitLab
- **Password** : Votre mot de passe GitLab (ou **Personal Access Token** recommandé)

### 5️⃣ Créer un Personal Access Token (Recommandé)

Au lieu d'utiliser votre mot de passe, créez un token :

1. GitLab → **Avatar (coin supérieur droit)** → **Edit profile**
2. Menu gauche → **Access Tokens**
3. **Add new token** :
   - **Name** : `tp-devsecops-token`
   - **Expiration date** : Choisir une date (ex: dans 1 an)
   - **Scopes** à cocher :
     - ✅ `api`
     - ✅ `read_repository`
     - ✅ `write_repository`
     - ✅ `read_registry`
     - ✅ `write_registry`
4. Cliquer sur **Create personal access token**
5. ⚠️ **COPIER LE TOKEN IMMÉDIATEMENT** (il ne sera plus affiché)

**Utilisation du token** :
```powershell
# Lors du push, utiliser le token comme mot de passe
# Username: votre_username
# Password: coller_le_token_ici
```

### 6️⃣ Vérifier dans GitLab

Après le push, vérifier dans GitLab :

1. **Code → Repository** : Vous devriez voir tous vos fichiers
2. **Code → Branches** : Vérifier que `main` et `develop` sont présentes
3. **Build → Pipelines** : Aucun pipeline pour le moment (normal)
4. **Deploy → Container Registry** : Registry activé mais vide (normal)

## 🔧 Commandes complètes (copier-coller)

### Option A : Si vous avez déjà créé le projet GitLab

```powershell
# Remplacer VOTRE_USERNAME par votre nom d'utilisateur GitLab réel
$GITLAB_USER = "VOTRE_USERNAME"

# Ajouter le remote
git remote add origin "https://gitlab.com/$GITLAB_USER/tp-devsecops-app.git"

# Vérifier
git remote -v

# Pousser les deux branches
git push -u origin main
git push -u origin develop

# Afficher le statut
Write-Host "`n✅ Code poussé avec succès vers GitLab !"
Write-Host "📍 URL du projet : https://gitlab.com/$GITLAB_USER/tp-devsecops-app"
```

### Option B : Si vous voulez changer l'utilisateur Git localement

```powershell
# Configurer votre nom et email
git config user.name "Votre Nom"
git config user.email "votre.email@example.com"

# Vérifier la configuration
git config --list | Select-String "user"
```

## 🔐 Configuration des Variables CI/CD

Une fois le code poussé, configurez les variables pour le pipeline :

### Dans GitLab : Settings → CI/CD → Variables → Expand

#### Variables AWS (pour le staging)

| Key | Value | Type | Protect | Mask |
|-----|-------|------|---------|------|
| `AWS_ACCESS_KEY_ID` | Votre Access Key | Variable | ✅ | ❌ |
| `AWS_SECRET_ACCESS_KEY` | Votre Secret Key | Variable | ✅ | ✅ |
| `AWS_DEFAULT_REGION` | `eu-west-1` | Variable | ❌ | ❌ |

#### Variables Azure (pour la production)

| Key | Value | Type | Protect | Mask |
|-----|-------|------|---------|------|
| `ARM_CLIENT_ID` | Service Principal App ID | Variable | ✅ | ❌ |
| `ARM_CLIENT_SECRET` | SP Password | Variable | ✅ | ✅ |
| `ARM_SUBSCRIPTION_ID` | Azure Subscription ID | Variable | ✅ | ❌ |
| `ARM_TENANT_ID` | Azure Tenant ID | Variable | ✅ | ❌ |

**Comment obtenir ces valeurs** :
- **AWS** : Voir [docs/GITLAB_SETUP.md](docs/GITLAB_SETUP.md)
- **Azure** : Voir [docs/GITLAB_SETUP.md](docs/GITLAB_SETUP.md)

## 🧪 Tester le pipeline

### Premier test (sans déploiement)

```powershell
# Créer une petite modification
echo "`n# Test Pipeline" >> README.md

# Commiter et pousser sur develop
git add README.md
git commit -m "test: vérification du pipeline CI/CD"
git push origin develop
```

**Résultat attendu** :
- GitLab : **Build → Pipelines** → Nouveau pipeline créé
- Stages : `test`, `security`, `build` s'exécutent
- Stage `deploy_staging` s'exécute (si variables AWS configurées)

### Vérifier les résultats

1. **GitLab → Build → Pipelines** : Cliquer sur le pipeline
2. Cliquer sur chaque job pour voir les logs :
   - ✅ `test` : Tests Jest passés
   - ✅ `security` : Aucun secret détecté
   - ✅ `build` : Image construite et poussée
3. **Deploy → Container Registry** : Vérifier que l'image apparaît

## 📊 Workflow recommandé

```
feature/* → develop → main
   ↓          ↓        ↓
   MR      AWS Auto  Azure Manual
```

1. **Développement** : Créer une branche `feature/ma-feature`
2. **Tests locaux** : `npm test`, `docker build`
3. **Push** : `git push origin feature/ma-feature`
4. **Merge Request** : Vers `develop`
5. **Staging** : Déploiement automatique sur AWS après merge dans `develop`
6. **Production** : Merge `develop` → `main`, puis déploiement manuel sur Azure

## ❓ Problèmes courants

### ❌ "remote origin already exists"

```powershell
# Supprimer l'ancien remote
git remote remove origin

# Ajouter le nouveau
git remote add origin https://gitlab.com/VOTRE_USERNAME/tp-devsecops-app.git
```

### ❌ "Authentication failed"

- Vérifier votre nom d'utilisateur
- Utiliser un **Personal Access Token** au lieu du mot de passe
- Vérifier les permissions du token

### ❌ "Repository not found"

- Vérifier l'URL du remote : `git remote -v`
- Vérifier que le projet existe sur GitLab
- Vérifier l'orthographe du nom d'utilisateur

### ❌ "Permission denied"

- Le projet doit être créé AVANT de pousser
- Vérifier que vous avez les droits d'écriture sur le projet

## 📚 Documentation

Pour plus de détails, consultez :
- [docs/GITLAB_SETUP.md](docs/GITLAB_SETUP.md) - Configuration complète GitLab
- [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) - Guide de déploiement
- [README.md](README.md) - Documentation principale

---

## ✅ Checklist finale

- [ ] Projet GitLab créé
- [ ] Remote origin ajouté
- [ ] Branche `main` poussée
- [ ] Branche `develop` poussée
- [ ] Code visible dans GitLab
- [ ] Variables CI/CD AWS configurées (optionnel pour l'instant)
- [ ] Variables CI/CD Azure configurées (optionnel pour l'instant)
- [ ] Premier pipeline testé
- [ ] Container Registry vérifié

---

**Prêt à pousser ? Suivez les étapes ci-dessus !** 🚀
