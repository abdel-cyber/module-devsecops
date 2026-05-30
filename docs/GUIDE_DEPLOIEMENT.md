# 🚀 Guide de Déploiement AWS & Azure

## 📋 Prérequis

- ✅ Credentials AWS configurés dans GitLab CI/CD Variables
- ✅ Variables Azure configurées dans GitLab CI/CD Variables  
- ✅ Image Docker publiée dans Container Registry
- ✅ Pipeline passant les stages test + security + build

---

## 🎯 OPTION 1 : Déploiement via GitLab CI/CD (Automatique)

### ✅ AWS STAGING (via GitLab Pipeline)

**⚠️ NOTE : Le job deploy_staging a actuellement une erreur de syntaxe. Utilisez l'OPTION 2 (déploiement local) en attendant la correction.**

1. Allez sur : https://gitlab.com/abdelmouiz99/tp-devsecops-app/-/pipelines
2. Trouvez le dernier pipeline sur la branche `develop`
3. Cliquez sur le bouton **Play (▶️)** du job `deploy_staging`
4. Attendez **5-10 minutes** (création EC2 + installation Docker)
5. Dans les logs, récupérez l'**IP publique**
6. Testez : `http://IP-PUBLIQUE/health`

### ✅ AZURE PRODUCTION (via GitLab Pipeline)

1. **Mergez develop dans main** :
   ```bash
   git checkout main
   git merge develop
   git push origin main
   ```

2. Allez sur le pipeline de la branche `main`
3. Cliquez sur **Play (▶️)** du job `deploy_production`
4. Attendez **3-5 minutes** (création App Service)
5. Dans les logs, récupérez l'**URL de production**
6. Testez : `https://app-name.azurewebsites.net/health`

---

## 🎯 OPTION 2 : Déploiement Local (Recommandé)

### ✅ AWS STAGING (Déploiement Local)

#### 1. Installez Terraform CLI
```powershell
choco install terraform
# Ou téléchargez depuis https://www.terraform.io/downloads
```

#### 2. Allez dans le dossier AWS
```powershell
cd terraform\aws-staging
```

#### 3. Créez le fichier `terraform.tfvars`
```hcl
# Copiez depuis terraform.tfvars.example et remplissez :

aws_region        = "eu-west-1"
instance_type     = "t2.micro"
docker_image      = "registry.gitlab.com/abdelmouiz99/tp-devsecops-app"
docker_tag        = "latest"
registry_url      = "registry.gitlab.com"
registry_user     = "votre-username-gitlab"
registry_password = "votre-deploy-token"  # Créez un Deploy Token dans GitLab
```

#### 4. Configurez les credentials AWS
```powershell
# Option A : Variables d'environnement (temporaire)
$env:AWS_ACCESS_KEY_ID = "votre-access-key"
$env:AWS_SECRET_ACCESS_KEY = "votre-secret-key"
$env:AWS_DEFAULT_REGION = "eu-west-1"

# Option B : AWS CLI (permanent)
aws configure
# Entrez vos credentials quand demandé
```

#### 5. Déployez avec Terraform
```powershell
terraform init        # Télécharge les providers AWS et TLS
terraform plan        # Prévisualise les ressources à créer
terraform apply       # Confirmer avec 'yes'
```

#### 6. Récupérez l'IP publique
```powershell
terraform output staging_public_ip
# Exemple de sortie : 3.127.45.89
```

#### 7. Testez l'application (attendez 2-3 min après apply)
```powershell
curl http://3.127.45.89/health
# Ou dans le navigateur
```

#### 8. Pour détruire les ressources (nettoyer)
```powershell
terraform destroy
```

---

### ✅ AZURE PRODUCTION (Déploiement Local)

#### 1. Installez Azure CLI
```powershell
choco install azure-cli
# Ou téléchargez depuis https://aka.ms/installazurecliwindows
```

#### 2. Connectez-vous à Azure
```powershell
az login
# Ouvre le navigateur pour authentification
```

#### 3. Créez un Service Principal
```powershell
az ad sp create-for-rbac --name "GitLab-Terraform" --role "Contributor" --scopes /subscriptions/YOUR_SUBSCRIPTION_ID
```

**Sauvegardez la sortie JSON** (vous en aurez besoin) :
```json
{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",           // ARM_CLIENT_ID
  "displayName": "GitLab-Terraform",
  "password": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",             // ARM_CLIENT_SECRET
  "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"            // ARM_TENANT_ID
}
```

#### 4. Trouvez votre Subscription ID
```powershell
az account show --query id -o tsv
# Exemple : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

#### 5. Allez dans le dossier Azure
```powershell
cd ..\azure-production
# Ou depuis la racine : cd terraform\azure-production
```

#### 6. Créez le fichier `terraform.tfvars`
```hcl
# Copiez depuis terraform.tfvars.example et remplissez :

resource_group_name = "tp-devsecops-rg"
azure_region        = "West Europe"
app_name            = "tp-devsecops-prod-uniqueid"  # Doit être GLOBALEMENT UNIQUE
docker_image        = "registry.gitlab.com/abdelmouiz99/tp-devsecops-app"
docker_image_tag    = "latest"
registry_url        = "https://registry.gitlab.com"
registry_user       = "votre-username-gitlab"
registry_password   = "votre-deploy-token"
```

#### 7. Configurez les credentials Azure
```powershell
$env:ARM_CLIENT_ID = "appId-du-service-principal"
$env:ARM_CLIENT_SECRET = "password-du-service-principal"
$env:ARM_SUBSCRIPTION_ID = "votre-subscription-id"
$env:ARM_TENANT_ID = "tenant-du-service-principal"
```

#### 8. Déployez avec Terraform
```powershell
terraform init        # Télécharge le provider Azure
terraform plan        # Prévisualise les ressources
terraform apply       # Confirmer avec 'yes'
```

#### 9. Récupérez l'URL de production
```powershell
terraform output production_url
# Exemple : https://tp-devsecops-prod-uniqueid.azurewebsites.net
```

#### 10. Testez l'application (attendez 2-3 min)
```powershell
curl https://tp-devsecops-prod-uniqueid.azurewebsites.net/health
# Ou dans le navigateur
```

#### 11. Pour détruire les ressources
```powershell
terraform destroy
```

---

## 📝 Configuration des Variables GitLab CI/CD

Pour utiliser **OPTION 1** (déploiement via pipeline), configurez ces variables :

### Accéder aux Variables
1. Allez sur : https://gitlab.com/abdelmouiz99/tp-devsecops-app/-/settings/ci_cd
2. Expandez la section **Variables**
3. Cliquez sur **Add variable**

### Variables AWS (pour deploy_staging)
| Key | Value | Protected | Masked |
|-----|-------|-----------|--------|
| `AWS_ACCESS_KEY_ID` | Votre Access Key ID | ✅ | ❌ |
| `AWS_SECRET_ACCESS_KEY` | Votre Secret Access Key | ✅ | ✅ |
| `AWS_DEFAULT_REGION` | `eu-west-1` | ❌ | ❌ |

### Variables Azure (pour deploy_production)
| Key | Value | Protected | Masked |
|-----|-------|-----------|--------|
| `ARM_CLIENT_ID` | appId du Service Principal | ✅ | ❌ |
| `ARM_CLIENT_SECRET` | password du Service Principal | ✅ | ✅ |
| `ARM_SUBSCRIPTION_ID` | Votre Subscription ID | ✅ | ❌ |
| `ARM_TENANT_ID` | tenant du Service Principal | ✅ | ❌ |

**Note** : Les variables `CI_REGISTRY`, `CI_REGISTRY_USER`, `CI_REGISTRY_PASSWORD` sont fournies automatiquement par GitLab.

---

## 🔍 Vérification et Tests

### Tester l'application AWS
```bash
# Endpoint health check
curl http://IP-PUBLIC/health

# Endpoint principal
curl http://IP-PUBLIC/

# Réponse attendue :
# {"message":"Bienvenue sur l'API DevSecOps !","version":"1.0.0"}
```

### Tester l'application Azure
```bash
# Endpoint health check
curl https://app-name.azurewebsites.net/health

# Endpoint principal
curl https://app-name.azurewebsites.net/

# Réponse attendue :
# {"message":"Bienvenue sur l'API DevSecOps !","version":"1.0.0"}
```

### Vérifier les logs Azure
```powershell
az webapp log tail --name tp-devsecops-prod-uniqueid --resource-group tp-devsecops-rg
```

---

## ⚠️ Troubleshooting

### AWS : Instance EC2 ne répond pas
1. **Attendez 2-3 minutes** après `terraform apply` (installation Docker + pull image)
2. Vérifiez le Security Group autorise le port 80 :
   ```powershell
   cd terraform\aws-staging
   terraform state show aws_security_group.staging_sg
   ```
3. Connectez-vous en SSH pour déboguer :
   ```powershell
   # Récupérez la clé privée
   terraform output -raw private_key > staging_key.pem
   
   # Sur Linux/Mac
   chmod 400 staging_key.pem
   ssh -i staging_key.pem ec2-user@IP-PUBLIC
   
   # Vérifiez le conteneur Docker
   sudo docker ps
   sudo docker logs $(sudo docker ps -q)
   ```

### Azure : App Service ne démarre pas
1. Vérifiez les logs dans le portail Azure :
   - https://portal.azure.com → App Services → Votre app → Log stream
2. Vérifiez que `WEBSITES_PORT=3000` est configuré
3. L'image Docker doit être accessible publiquement ou avec credentials valides

### Erreur "Terraform has no command named 'sh'"
C'est un problème connu du pipeline GitLab. **Utilisez OPTION 2** (déploiement local).

### Erreur "Access Denied" AWS
- Vérifiez que vos credentials AWS sont valides
- Si vous utilisez AWS Academy, les credentials expirent après 4 heures
- Récupérez de nouveaux credentials depuis AWS Details

### Erreur "Unauthorized" Azure
- Vérifiez que le Service Principal a le rôle **Contributor**
- Les 4 variables ARM_* doivent être correctement configurées
- Le Service Principal doit avoir accès à la Subscription

---

## 📊 Coûts Estimés

### AWS
- **EC2 t2.micro** : ~$0.0116/heure (~$8.50/mois)
- **Données sortantes** : $0.09/GB (premiers 10 GB gratuits/mois)
- **Total estimation** : ~$10/mois
- **AWS Free Tier** : 750 heures/mois gratuites la première année

### Azure
- **App Service Plan B1** : ~€11/mois
- **Pas de coût pour données sortantes** dans la plupart des cas
- **Total estimation** : ~€11/mois
- **Free Tier** : 10 web apps F1 gratuites (mais limitées)

**⚠️ Important** : N'oubliez pas de détruire les ressources après vos tests !
```powershell
terraform destroy
```

---

## 📸 Captures d'écran pour le TP

Pour votre livrable, prenez ces captures :

1. **Pipeline GitLab complet** (stages test, security, build passés)
2. **Container Registry** avec l'image et les tags
3. **Job deploy_staging logs** (si vous utilisez GitLab CI)
4. **Terminal avec terraform apply** (si déploiement local)
5. **Sortie de terraform output** (IP AWS ou URL Azure)
6. **Test curl** sur `/health` montrant la réponse JSON
7. **Page web dans le navigateur** montrant l'application

---

## 🎯 Récapitulatif Final

✅ **Minimum pour valider le TP** :
- Pipeline GitLab avec stages test + security + build ✅ FAIT
- Image dans Container Registry ✅ À VÉRIFIER
- Code Terraform AWS + Azure ✅ FAIT

✅ **Bonus (déploiements réels)** :
- Déploiement AWS Staging (OPTION 2 recommandée)
- Déploiement Azure Production (OPTION 2 recommandée)

**Recommandation** : Utilisez l'**OPTION 2** (déploiement local) car le job GitLab CI a une erreur de syntaxe non résolue.

---

## 📚 Documentation Complémentaire

- [docs/CREDENTIALS_SETUP.md](./CREDENTIALS_SETUP.md) - Guide détaillé credentials
- [docs/DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - Guide de déploiement complet
- [docs/TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Résolution de problèmes
- [terraform/aws-staging/README.md](../terraform/aws-staging/README.md) - AWS staging
- [terraform/azure-production/README.md](../terraform/azure-production/README.md) - Azure production

---

**Besoin d'aide ?** Consultez les logs détaillés ou contactez votre enseignant.
