# Terraform Kubernetes Production

Ce module Terraform déploie l'application sur un cluster Kubernetes (production).

## Architecture

- **Provider** : `hashicorp/kubernetes` v2.23
- **Namespace** : `tp-devsecops-production`
- **Deployment** : 3 pods avec RollingUpdate (zero downtime)
- **Service** : LoadBalancer port 80 → 3000
- **Secret** : Credentials GitLab Container Registry

## Différences avec Staging

| Configuration | Staging | Production |
|---------------|---------|------------|
| Namespace | tp-devsecops-staging | tp-devsecops-production |
| Replicas | 3 | 3 |
| maxUnavailable | 1 | 0 (zero downtime) |
| RAM | 128-256Mi | 256-512Mi |
| CPU | 100-200m | 200-500m |
| Docker Tag | $CI_COMMIT_SHORT_SHA | latest |
| Health Check Delay | 10s | 15s |

## Prérequis

1. **kubectl** configuré avec accès au cluster production
2. **Terraform** v1.0+ installé
3. **Kubeconfig** avec le contexte production configuré

## Configuration

### 1. Créer terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
```

Éditez `terraform.tfvars` et ajustez :
- `kubeconfig_path` : Chemin vers votre kubeconfig
- `registry_password` : Votre Deploy Token GitLab

## Déploiement

### Initialisation

```bash
terraform init
```

### Plan

```bash
terraform plan \
  -var="docker_image=registry.gitlab.com/abdelmouiz99/tp-devsecops-app" \
  -var="docker_tag=latest" \
  -var="registry_user=abdelmouiz99" \
  -var="registry_password=VOTRE_TOKEN"
```

### Apply

```bash
terraform apply \
  -var="docker_image=registry.gitlab.com/abdelmouiz99/tp-devsecops-app" \
  -var="docker_tag=latest" \
  -var="registry_user=abdelmouiz99" \
  -var="registry_password=VOTRE_TOKEN"
```

### Vérification

```bash
# Voir les 3 pods en production
kubectl get pods -n tp-devsecops-production -o wide

# Voir le service
kubectl get service -n tp-devsecops-production

# Logs
kubectl logs -f -l app=devsecops-app -n tp-devsecops-production

# Métriques
kubectl top pods -n tp-devsecops-production
```

### Destruction

```bash
terraform destroy
```

## Utilisation dans GitLab CI/CD

Ce module est utilisé automatiquement dans `.gitlab-ci.yml` :

```yaml
deploy_production:
  stage: deploy_production
  image: hashicorp/terraform:latest
  script:
    - cd terraform/k8s-production
    - terraform init
    - terraform apply -auto-approve \
        -var="docker_image=$CI_REGISTRY_IMAGE" \
        -var="docker_tag=latest" \
        -var="registry_user=$CI_REGISTRY_USER" \
        -var="registry_password=$CI_REGISTRY_PASSWORD"
```

Le kubeconfig est injecté via la variable `KUBE_CONFIG_PRODUCTION` (base64).

## Monitoring Production

```bash
# Statut du rollout
kubectl rollout status deployment/devsecops-app -n tp-devsecops-production

# Historique des déploiements
kubectl rollout history deployment/devsecops-app -n tp-devsecops-production

# Rollback en cas de problème
kubectl rollout undo deployment/devsecops-app -n tp-devsecops-production

# Événements
kubectl get events -n tp-devsecops-production --sort-by='.lastTimestamp'

# Endpoints (doit montrer 3 IPs)
kubectl get endpoints -n tp-devsecops-production
```

## Haute Disponibilité

La configuration production garantit :
- ✅ **3 pods** répartis sur le cluster
- ✅ **Zero downtime** lors des mises à jour (maxUnavailable=0)
- ✅ **Health checks** stricts (15s initial delay)
- ✅ **Resources** augmentées (512Mi RAM, 500m CPU)
- ✅ **Rolling updates** progressifs

---

**Production ready avec Terraform + Kubernetes ! 🚀**
