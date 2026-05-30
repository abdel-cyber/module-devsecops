# 🔐 Guide de Configuration des Credentials Cloud

Ce guide vous aide à configurer les credentials AWS et Azure dans GitLab CI/CD pour les déploiements automatiques.

---

## 📋 Vue d'ensemble

**Vous aurez besoin de :**
- ✅ Compte AWS avec accès programmatique
- ✅ Compte Azure avec Service Principal
- ✅ Accès aux Settings GitLab de votre projet

---

## 🔧 ÉTAPE 1 : Configurer les Variables GitLab CI/CD

### 1.1 Accéder aux Variables CI/CD

1. Allez sur votre projet GitLab : https://gitlab.com/abdelmouiz99/tp-devsecops-app
2. Cliquez sur **Settings** (menu de gauche)
3. Cliquez sur **CI/CD**
4. Trouvez la section **Variables** et cliquez sur **Expand**
5. Cliquez sur **Add variable**

### 1.2 Propriétés importantes des variables

Pour CHAQUE variable que vous créez :
- ✅ **Protected** : ☐ Non coché (sauf si vous déployez uniquement depuis branches protégées)
- ✅ **Masked** : ☑ Coché (masque la valeur dans les logs)
- ✅ **Expand variable reference** : ☐ Non coché

---

## ☁️ ÉTAPE 2 : Configurer AWS

### 2.1 Obtenir les Credentials AWS

**Option A - Compte AWS Academy (étudiants)** :
1. Connectez-vous à AWS Academy
2. Cliquez sur **AWS Details**
3. Cliquez sur **Show AWS CLI credentials**
4. Copiez les valeurs :
   - `aws_access_key_id`
   - `aws_secret_access_key`
   - `aws_session_token` (si présent)

**Option B - Compte AWS Personnel** :
1. Connectez-vous à la console AWS
2. Allez dans **IAM** → **Users**
3. Cliquez sur votre utilisateur (ou créez-en un)
4. Onglet **Security credentials**
5. Cliquez sur **Create access key**
6. Choisissez **CLI** comme use case
7. Notez :
   - Access Key ID
   - Secret Access Key

### 2.2 Ajouter les Variables AWS dans GitLab

Créez les variables suivantes dans GitLab CI/CD Variables :

| Key | Value | Exemple |
|-----|-------|---------|
| `AWS_ACCESS_KEY_ID` | Votre Access Key ID | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | Votre Secret Access Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_DEFAULT_REGION` | Région AWS | `eu-west-1` |

**Si vous utilisez AWS Academy (session token requis)** :
| Key | Value |
|-----|-------|
| `AWS_SESSION_TOKEN` | Votre Session Token |

⚠️ **Important** : Les credentials AWS Academy expirent après quelques heures. Vous devrez les renouveler régulièrement.

### 2.3 Vérifier les Permissions AWS

Votre utilisateur AWS doit avoir les permissions pour :
- ✅ Créer des instances EC2
- ✅ Créer des Security Groups
- ✅ Créer des Key Pairs
- ✅ Lire les VPC et Subnets

**IAM Policy minimum** :
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "vpc:*"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## ☁️ ÉTAPE 3 : Configurer Azure

### 3.1 Vérifier votre Abonnement Azure

1. Connectez-vous au portail Azure : https://portal.azure.com
2. Cherchez **Subscriptions** (Abonnements)
3. Notez votre **Subscription ID** (format : `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

### 3.2 Créer un Service Principal

**Option 1 - Via Azure Portal** :
1. Allez dans **Azure Active Directory** → **App registrations**
2. Cliquez sur **New registration**
3. Nom : `GitLab-Terraform-Deploy`
4. Cliquez **Register**
5. Notez :
   - **Application (client) ID** = `ARM_CLIENT_ID`
   - **Directory (tenant) ID** = `ARM_TENANT_ID`
6. Allez dans **Certificates & secrets**
7. Cliquez **New client secret**
8. Description : `GitLab CI/CD`
9. Expiration : 6 mois ou 1 an
10. Cliquez **Add**
11. **COPIEZ IMMÉDIATEMENT** la valeur du secret (affiché 1 seule fois !) = `ARM_CLIENT_SECRET`

**Option 2 - Via Azure CLI (plus rapide)** :

Installez Azure CLI : https://docs.microsoft.com/cli/azure/install-azure-cli

```bash
# Se connecter
az login

# Créer le Service Principal
az ad sp create-for-rbac --name "GitLab-Terraform" --role="Contributor" --scopes="/subscriptions/VOTRE_SUBSCRIPTION_ID"
```

Vous obtiendrez :
```json
{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",        ← ARM_CLIENT_ID
  "displayName": "GitLab-Terraform",
  "password": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",     ← ARM_CLIENT_SECRET
  "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"        ← ARM_TENANT_ID
}
```

### 3.3 Ajouter les Variables Azure dans GitLab

Créez les variables suivantes dans GitLab CI/CD Variables :

| Key | Value | Description |
|-----|-------|-------------|
| `ARM_CLIENT_ID` | Application (client) ID | ID de l'application Azure AD |
| `ARM_CLIENT_SECRET` | Client secret (password) | Secret client (MASKED) |
| `ARM_SUBSCRIPTION_ID` | Subscription ID | ID de votre abonnement Azure |
| `ARM_TENANT_ID` | Directory (tenant) ID | ID du tenant Azure AD |

### 3.4 Donner les Permissions au Service Principal

1. Allez dans **Subscriptions** → Sélectionnez votre abonnement
2. Cliquez sur **Access control (IAM)**
3. Cliquez **Add** → **Add role assignment**
4. Rôle : **Contributor**
5. Assign access to : **User, group, or service principal**
6. Cherchez : `GitLab-Terraform` (ou le nom de votre Service Principal)
7. Cliquez **Save**

---

## 🔄 ÉTAPE 4 : Créer un GitLab Deploy Token

Pour que AWS/Azure puissent tirer l'image Docker :

1. Dans GitLab : **Settings** → **Repository**
2. Section **Deploy tokens** → **Expand**
3. Cliquez **Add token**
4. Configurez :
   - **Name** : `terraform-registry-access`
   - **Expires at** : (optionnel, laissez vide pour jamais expirer)
   - **Username** : `deploy-user` (ou laissez générer automatiquement)
   - **Scopes** : ☑ Cochez uniquement `read_registry`
5. Cliquez **Create deploy token**
6. **COPIEZ IMMÉDIATEMENT** (affichés 1 seule fois !) :
   - Username : `gitlab+deploy-token-XXXXXX`
   - Token : `glpat-XXXXXXXXXXXXX`

⚠️ **Ces credentials sont déjà injectés automatiquement comme** `$CI_REGISTRY_USER` **et** `$CI_REGISTRY_PASSWORD` **dans le pipeline GitLab, donc normalement vous n'avez rien à faire manuellement !**

---

## ✅ ÉTAPE 5 : Vérifier la Configuration

### 5.1 Vérifier que les Variables sont Définies

1. Allez dans **Settings** → **CI/CD** → **Variables**
2. Vérifiez que vous avez au minimum :

**Pour AWS** :
- ✅ `AWS_ACCESS_KEY_ID`
- ✅ `AWS_SECRET_ACCESS_KEY`
- ✅ `AWS_DEFAULT_REGION`

**Pour Azure** :
- ✅ `ARM_CLIENT_ID`
- ✅ `ARM_CLIENT_SECRET`
- ✅ `ARM_SUBSCRIPTION_ID`
- ✅ `ARM_TENANT_ID`

### 5.2 Tester le Pipeline

1. Déclenchez un nouveau pipeline :
   ```bash
   git commit --allow-empty -m "test: trigger pipeline"
   git push origin develop
   ```

2. Allez dans **CI/CD** → **Pipelines**
3. Attendez que les stages `test`, `security`, et `build` passent au VERT
4. Le stage `deploy_staging` apparaîtra avec un bouton **Play** (▶️)
5. Cliquez sur **Play** pour lancer le déploiement AWS
6. Surveillez les logs pour voir si le déploiement réussit

### 5.3 En cas d'erreur

**Erreur : "Error: No valid credential sources found"**
- ✅ Vérifiez que les variables AWS sont bien définies dans GitLab
- ✅ Vérifiez l'orthographe exacte : `AWS_ACCESS_KEY_ID`, pas `AWS_ACCESS_KEY`
- ✅ Vérifiez que **Masked** est coché

**Erreur : "Access Denied" ou "UnauthorizedOperation"**
- ✅ Vérifiez les permissions IAM de votre utilisateur AWS
- ✅ Ajoutez la policy `AmazonEC2FullAccess` temporairement pour tester

**Erreur Azure : "AuthenticationFailed"**
- ✅ Vérifiez que les 4 variables ARM_* sont définies
- ✅ Vérifiez que le Service Principal a le rôle Contributor
- ✅ Le `ARM_CLIENT_SECRET` expire peut-être (recréez-en un)

---

## 📸 Étape 6 : Captures pour le Rapport

Une fois le pipeline réussi, prenez ces captures :

1. **Pipeline complet** : Tous les stages en VERT
2. **Stage security** : Logs montrant "✅ Aucun secret suspect détecté"
3. **Container Registry** : Deploy → Container Registry avec les tags
4. **Sortie Terraform AWS** : IP publique de l'instance
5. **Sortie Terraform Azure** : URL de l'App Service
6. **Test /health AWS** : `curl http://IP:3000/health`
7. **Test /health Azure** : `curl https://app-name.azurewebsites.net/health`

---

## 📝 Résumé - Checklist Complète

### Avant de déployer :
- [ ] Variables AWS configurées dans GitLab CI/CD
- [ ] Variables Azure configurées dans GitLab CI/CD
- [ ] GitLab Deploy Token créé (automatique via CI_REGISTRY_*)
- [ ] Pipeline test+security+build réussi (stages verts)
- [ ] Image Docker présente dans Container Registry

### Pour déployer AWS (staging) :
- [ ] Aller dans Pipelines → Cliquer sur le pipeline en cours
- [ ] Cliquer sur le bouton **Play** (▶️) du job `deploy_staging`
- [ ] Attendre 5-10 minutes (création EC2 + installation Docker)
- [ ] Récupérer l'IP publique dans les logs Terraform
- [ ] Tester : `curl http://IP/health`

### Pour déployer Azure (production) :
- [ ] Merger develop dans main : `git checkout main && git merge develop && git push`
- [ ] Aller dans Pipelines → Cliquer sur le pipeline main
- [ ] Cliquer sur le bouton **Play** (▶️) du job `deploy_production`
- [ ] Attendre 3-5 minutes (création App Service)
- [ ] Récupérer l'URL dans les logs Terraform
- [ ] Tester : `curl https://app-name.azurewebsites.net/health`

---

## 🆘 Support

Si vous rencontrez des problèmes :
1. Consultez les logs du pipeline GitLab (très détaillés)
2. Vérifiez le fichier [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
3. Vérifiez que vos credentials cloud n'ont pas expiré (surtout AWS Academy)

---

## 🔗 Liens Utiles

- [GitLab CI/CD Variables](https://docs.gitlab.com/ee/ci/variables/)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Azure Service Principal](https://docs.microsoft.com/azure/active-directory/develop/howto-create-service-principal-portal)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
