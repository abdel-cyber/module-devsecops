# 🚀 Déploiement Kubernetes via Terraform

## Vue d'ensemble

Ce projet utilise **Terraform** avec le **provider Kubernetes** pour déployer l'application sur 2 clusters distincts :

- **Cluster 1 (Staging)** : Environnement de test
- **Cluster 2 (Production)** : Environnement production avec haute disponibilité

**Avantage** : Infrastructure as Code complète avec gestion déclarative des ressources Kubernetes.

---

## 🏗️ Architecture

```
GitLab CI/CD Pipeline
│
├─> Stage: test (Jest + Supertest)
├─> Stage: security (Grep secret scanning)
├─> Stage: build (Docker image)
│   └─> GitLab Container Registry
│
├─> Stage: deploy_staging (manuel)
│   └─> Terraform + Provider Kubernetes
│       └─> Cluster 1 (Staging)
│           ├─ Namespace: tp-devsecops-staging
│           ├─ Secret: gitlab-registry-secret
│           ├─ Deployment: 3 pods
│           └─ Service: LoadBalancer
│
└─> Stage: deploy_production (manuel)
    └─> Terraform + Provider Kubernetes
        └─> Cluster 2 (Production)
            ├─ Namespace: tp-devsecops-production
            ├─ Secret: gitlab-registry-secret
            ├─ Deployment: 3 pods (zero downtime)
            └─ Service: LoadBalancer
```

---

## 📁 Structure des Fichiers

```
terraform/
├── k8s-staging/                      # Configuration Terraform Staging
│   ├── main.tf                       # Ressources Kubernetes (namespace, deployment, service, secret)
│   ├── variables.tf                  # Variables d'entrée
│   ├── outputs.tf                    # Outputs (namespace, service, replicas)
│   ├── terraform.tfvars.example      # Template de configuration
│   └── README.md                     # Documentation
│
├── k8s-production/                   # Configuration Terraform Production
│   ├── main.tf                       # Ressources Kubernetes (haute disponibilité)
│   ├── variables.tf                  # Variables d'entrée
│   ├── outputs.tf                    # Outputs (namespace, service, replicas)
│   ├── terraform.tfvars.example      # Template de configuration
│   └── README.md                     # Documentation
│
└── [aws-staging/]                    # Ancien déploiement AWS (conservé pour référence)
    └── [azure-production/]           # Ancien déploiement Azure (conservé pour référence)

kubernetes/                            # Manifestes YAML (référence uniquement)
├── staging/                          # Les manifestes sont maintenant gérés par Terraform
│   ├── namespace.yaml
│   ├── deployment.yaml
│   └── service.yaml
└── production/
    ├── namespace.yaml
    ├── deployment.yaml
    └── service.yaml
```

---

## 🔧 Prérequis

### 1. Outils nécessaires

```bash
# Terraform
terraform version  # v1.0+ requis

# kubectl
kubectl version --client

# Accès aux clusters Kubernetes
kubectl config get-contexts
```

### 2. Clusters Kubernetes

Vous avez besoin de **2 clusters Kubernetes** distincts :

#### Options locales (développement) :
- **Minikube** : `minikube start --profile staging` et `minikube start --profile production`
- **Docker Desktop** : Activer Kubernetes dans les settings
- **K3s** : Installation légère pour tests

#### Options cloud (production réelle) :
- **Amazon EKS** (AWS)
- **Azure AKS** (Azure)
- **Google GKE** (Google Cloud)
- **DigitalOcean Kubernetes**

### 3. Configuration kubectl

```bash
# Lister les contextes disponibles
kubectl config get-contexts

# Créer/modifier un contexte pour staging
kubectl config set-context staging-context --cluster=nom-cluster-staging --user=user-staging

# Créer/modifier un contexte pour production
kubectl config set-context production-context --cluster=nom-cluster-production --user=user-production

# Basculer entre les contextes
kubectl config use-context staging-context
kubectl config use-context production-context
```

---

## 🚀 Déploiement Manuel (pour tests locaux)

### Déploiement STAGING

#### 1. Configurer le contexte Kubernetes

```bash
kubectl config use-context staging-context
kubectl cluster-info
```

#### 2. Aller dans le dossier Terraform

```bash
cd terraform/k8s-staging
```

#### 3. Créer le fichier de configuration

```bash
cp terraform.tfvars.example terraform.tfvars
```

Éditez `terraform.tfvars` :
```hcl
kubeconfig_path   = "~/.kube/config"
docker_image      = "registry.gitlab.com/abdelmouiz99/tp-devsecops-app"
docker_tag        = "latest"
registry_user     = "abdelmouiz99"
registry_password = "VOTRE_DEPLOY_TOKEN"
```

#### 4. Initialiser Terraform

```bash
terraform init
```

Télécharge le provider `hashicorp/kubernetes` v2.23.

#### 5. Planifier le déploiement

```bash
terraform plan
```

Affiche les ressources qui seront créées :
- 1 namespace
- 1 secret (dockerconfigjson)
- 1 deployment (3 replicas)
- 1 service (LoadBalancer)

#### 6. Appliquer le déploiement

```bash
terraform apply
```

Tapez `yes` pour confirmer.

#### 7. Vérifier le déploiement

```bash
# Outputs Terraform
terraform output

# Liste des pods (3 doivent être Running)
kubectl get pods -n tp-devsecops-staging

# Service et IP externe
kubectl get service -n tp-devsecops-staging

# Logs des pods
kubectl logs -f -l app=devsecops-app -n tp-devsecops-staging
```

#### 8. Tester l'application

```bash
# Récupérer l'IP externe
EXTERNAL_IP=$(kubectl get service devsecops-app-service -n tp-devsecops-staging -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Tester le endpoint /health
curl http://$EXTERNAL_IP/health

# Tester le endpoint principal
curl http://$EXTERNAL_IP/
```

### Déploiement PRODUCTION

Même processus avec le dossier `terraform/k8s-production` :

```bash
kubectl config use-context production-context
cd terraform/k8s-production
cp terraform.tfvars.example terraform.tfvars
# Éditez terraform.tfvars
terraform init
terraform plan
terraform apply
```

---

## 🤖 Déploiement Automatique via GitLab CI/CD

### Configuration des Variables GitLab

Allez sur : `https://gitlab.com/abdelmouiz99/tp-devsecops-app/-/settings/ci_cd`

Ajoutez ces variables :

| Variable | Description | Type | Masked | Protected |
|----------|-------------|------|--------|-----------|
| `KUBE_CONFIG_STAGING` | Kubeconfig cluster staging (base64) | Variable | ✅ | ❌ |
| `KUBE_CONFIG_PRODUCTION` | Kubeconfig cluster production (base64) | Variable | ✅ | ✅ |

### Comment obtenir KUBE_CONFIG encodé en base64

#### Pour Staging :

```bash
# Basculer sur le contexte staging
kubectl config use-context staging-context

# Exporter et encoder en base64
kubectl config view --flatten --minify | base64 -w 0

# Sur macOS/Windows sans -w 0 :
kubectl config view --flatten --minify | base64

# Copiez la sortie complète dans KUBE_CONFIG_STAGING
```

#### Pour Production :

```bash
# Basculer sur le contexte production
kubectl config use-context production-context

# Exporter et encoder
kubectl config view --flatten --minify | base64 -w 0

# Copiez la sortie dans KUBE_CONFIG_PRODUCTION
```

### Déclencher le déploiement

#### Staging (branche develop) :

1. Poussez sur `develop` :
   ```bash
   git checkout develop
   git add .
   git commit -m "Update staging"
   git push origin develop
   ```

2. Allez sur : `https://gitlab.com/abdelmouiz99/tp-devsecops-app/-/pipelines`

3. Attendez que les stages `test`, `security`, `build` passent

4. Cliquez sur **Play (▶️)** pour `deploy_staging`

5. Le pipeline va :
   - Décoder le kubeconfig
   - Exécuter `terraform init`
   - Exécuter `terraform plan`
   - Exécuter `terraform apply -auto-approve`
   - Afficher les outputs (namespace, replicas, service)

#### Production (branche main) :

1. Mergez `develop` dans `main` :
   ```bash
   git checkout main
   git merge develop
   git push origin main
   ```

2. Allez sur le pipeline de `main`

3. Cliquez sur **Play (▶️)** pour `deploy_production`

---

## 📊 Comparaison Staging vs Production

| Configuration | Staging | Production |
|---------------|---------|------------|
| **Namespace** | tp-devsecops-staging | tp-devsecops-production |
| **Pods** | 3 réplicas | 3 réplicas |
| **Docker Tag** | $CI_COMMIT_SHORT_SHA | latest |
| **maxUnavailable** | 1 (downtime possible) | 0 (zero downtime) |
| **RAM** | 128-256Mi | 256-512Mi |
| **CPU** | 100-200m | 200-500m |
| **Liveness Initial Delay** | 10s | 15s |
| **Readiness Initial Delay** | 5s | 10s |
| **Environment Variable** | NODE_ENV=staging | NODE_ENV=production |

---

## 🔍 Commandes Terraform Utiles

### Voir l'état actuel

```bash
terraform show
```

### Lister les ressources gérées

```bash
terraform state list
```

### Détails d'une ressource

```bash
terraform state show kubernetes_deployment.app
```

### Mettre à jour une ressource

```bash
# Modifier terraform.tfvars ou main.tf
terraform plan
terraform apply
```

### Détruire l'infrastructure

```bash
# Staging
cd terraform/k8s-staging
terraform destroy

# Production
cd terraform/k8s-production
terraform destroy
```

### Importer une ressource existante

Si vous avez déjà un deployment créé manuellement :

```bash
terraform import kubernetes_deployment.app tp-devsecops-staging/devsecops-app
```

---

## 🛠️ Troubleshooting

### Erreur : "Unable to connect to the server"

**Problème** : Terraform ne peut pas se connecter au cluster Kubernetes.

**Solution** :
```bash
# Vérifier le kubeconfig
kubectl cluster-info
kubectl get nodes

# Vérifier le contexte
kubectl config current-context

# Tester manuellement
kubectl get namespaces
```

### Erreur : "ImagePullBackOff"

**Problème** : Le secret Docker Registry est incorrect.

**Solution** :
```bash
# Vérifier le secret créé
kubectl get secret gitlab-registry-secret -n tp-devsecops-staging -o yaml

# Recréer le secret manuellement
kubectl create secret docker-registry gitlab-registry-secret \
  --docker-server=registry.gitlab.com \
  --docker-username=abdelmouiz99 \
  --docker-password=VOTRE_TOKEN \
  --namespace=tp-devsecops-staging
```

### Erreur : "Service remains in <pending>"

**Problème** : LoadBalancer non supporté (Minikube, Docker Desktop).

**Solution Minikube** :
```bash
minikube tunnel
```

**Solution alternative** : Changer le type de service en `NodePort` dans `main.tf` :
```hcl
spec {
  type = "NodePort"  # Au lieu de LoadBalancer
  ...
}
```

### Erreur : "Error acquiring the state lock"

**Problème** : Terraform state verrouillé (job pipeline précédent crashé).

**Solution** :
```bash
terraform force-unlock LOCK_ID
```

### Pipeline GitLab : "KUBE_CONFIG_STAGING not found"

**Problème** : Variable non configurée dans GitLab.

**Solution** :
1. Allez sur Settings > CI/CD > Variables
2. Ajoutez `KUBE_CONFIG_STAGING` avec le kubeconfig encodé en base64
3. Cochez "Masked"

---

## 📈 Monitoring et Observabilité

### Voir les pods en temps réel

```bash
# Staging
watch kubectl get pods -n tp-devsecops-staging

# Production
watch kubectl get pods -n tp-devsecops-production
```

### Logs agrégés

```bash
# Tous les pods en staging
kubectl logs -f -l app=devsecops-app -n tp-devsecops-staging --max-log-requests=10

# Tous les pods en production
kubectl logs -f -l app=devsecops-app -n tp-devsecops-production --max-log-requests=10
```

### Métriques (si metrics-server installé)

```bash
kubectl top pods -n tp-devsecops-staging
kubectl top pods -n tp-devsecops-production
```

### Événements Kubernetes

```bash
kubectl get events -n tp-devsecops-staging --sort-by='.lastTimestamp'
kubectl get events -n tp-devsecops-production --sort-by='.lastTimestamp'
```

### Rollout Status

```bash
# Suivre un déploiement
kubectl rollout status deployment/devsecops-app -n tp-devsecops-staging

# Historique des déploiements
kubectl rollout history deployment/devsecops-app -n tp-devsecops-staging

# Rollback
kubectl rollout undo deployment/devsecops-app -n tp-devsecops-staging
```

---

## 🎯 Avantages de Terraform + Kubernetes

| Avantage | Description |
|----------|-------------|
| **Infrastructure as Code** | Configuration déclarative versionnée dans Git |
| **État consistant** | Terraform state garantit la cohérence |
| **Idempotence** | Plusieurs `terraform apply` donnent le même résultat |
| **Plan before apply** | Prévisualisation des changements avant application |
| **Rollback facile** | `terraform destroy` + `terraform apply` avec ancien state |
| **Multi-cloud** | Même syntaxe pour AWS, Azure, GCP, Kubernetes |
| **Gestion des secrets** | Variables sensibles marquées `sensitive = true` |
| **CI/CD intégré** | Automatisation complète via GitLab |

---

## 📚 Ressources Complémentaires

### Documentation Officielle

- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [Terraform Language](https://www.terraform.io/language)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

### Exemples de Ressources Terraform Kubernetes

```hcl
# ConfigMap
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.staging.metadata[0].name
  }
  data = {
    LOG_LEVEL = "debug"
  }
}

# Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v2" "app" {
  metadata {
    name      = "devsecops-app-hpa"
    namespace = kubernetes_namespace.staging.metadata[0].name
  }
  spec {
    max_replicas = 10
    min_replicas = 3
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.app.metadata[0].name
    }
    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
  }
}

# Ingress (si vous avez un Ingress Controller)
resource "kubernetes_ingress_v1" "app" {
  metadata {
    name      = "devsecops-app-ingress"
    namespace = kubernetes_namespace.staging.metadata[0].name
  }
  spec {
    rule {
      host = "staging.example.com"
      http {
        path {
          path = "/"
          backend {
            service {
              name = kubernetes_service.app.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
```

---

## ✅ Checklist de Déploiement

### Avant le premier déploiement :

- [ ] Terraform installé (v1.0+)
- [ ] kubectl installé et configuré
- [ ] 2 clusters Kubernetes accessibles
- [ ] 2 contextes kubectl configurés (staging, production)
- [ ] Variables GitLab CI/CD configurées (`KUBE_CONFIG_STAGING`, `KUBE_CONFIG_PRODUCTION`)
- [ ] Deploy Token GitLab créé
- [ ] Fichiers `terraform.tfvars` créés (staging + production)

### Pour chaque déploiement :

- [ ] Code poussé sur develop (staging) ou main (production)
- [ ] Pipeline test + security + build passent
- [ ] Clic sur Play pour deploy_staging ou deploy_production
- [ ] Vérification : `kubectl get pods -n tp-devsecops-{staging|production}`
- [ ] Test de l'API : `curl http://EXTERNAL_IP/health`
- [ ] Vérification des logs : `kubectl logs -f -l app=devsecops-app -n ...`

---

**✅ Configuration Terraform + Kubernetes complète ! Déploiement IaC avec 3 pods par cluster.** 🚀
