# Terraform Kubernetes Staging

Ce module Terraform déploie l'application sur un cluster Kubernetes (staging).

## Architecture

- **Provider** : `hashicorp/kubernetes` v2.23
- **Namespace** : `tp-devsecops-staging`
- **Deployment** : 3 pods avec RollingUpdate
- **Service** : LoadBalancer port 80 → 3000
- **Secret** : Credentials GitLab Container Registry

## Prérequis

1. **kubectl** configuré avec accès au cluster staging
2. **Terraform** v1.0+ installé
3. **Kubeconfig** avec le contexte staging configuré

## Configuration

### 1. Créer terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
```

Éditez `terraform.tfvars` et ajustez :
- `kubeconfig_path` : Chemin vers votre kubeconfig
- `registry_password` : Votre Deploy Token GitLab

### 2. Variables obligatoires

| Variable | Description |
|----------|-------------|
| `docker_image` | Image Docker (ex: registry.gitlab.com/user/repo) |
| `registry_user` | Username GitLab ou Deploy Token username |
| `registry_password` | Deploy Token GitLab |

### 3. Variables optionnelles

| Variable | Défaut | Description |
|----------|--------|-------------|
| `kubeconfig_path` | `~/.kube/config` | Chemin kubeconfig |
| `docker_tag` | `latest` | Tag de l'image |
| `registry_url` | `registry.gitlab.com` | URL du registry |
| `registry_email` | `ci@gitlab.com` | Email pour le registry |

## Déploiement

### Initialisation

```bash
terraform init
```

### Plan (prévisualiser les changements)

```bash
terraform plan \
  -var="docker_image=registry.gitlab.com/abdelmouiz99/tp-devsecops-app" \
  -var="docker_tag=abc123" \
  -var="registry_user=abdelmouiz99" \
  -var="registry_password=VOTRE_TOKEN"
```

### Apply (déployer)

```bash
terraform apply \
  -var="docker_image=registry.gitlab.com/abdelmouiz99/tp-devsecops-app" \
  -var="docker_tag=abc123" \
  -var="registry_user=abdelmouiz99" \
  -var="registry_password=VOTRE_TOKEN"
```

### Outputs

Après l'apply, vous obtiendrez :

```
namespace         = "tp-devsecops-staging"
deployment_name   = "devsecops-app"
service_name      = "devsecops-app-service"
replicas          = 3
service_type      = "LoadBalancer"
service_port      = 80
image_deployed    = "registry.gitlab.com/abdelmouiz99/tp-devsecops-app:abc123"
```

### Vérification

```bash
# Voir les pods (3 doivent être en Running)
kubectl get pods -n tp-devsecops-staging

# Voir le service et son IP externe
kubectl get service -n tp-devsecops-staging

# Logs
kubectl logs -f -l app=devsecops-app -n tp-devsecops-staging
```

### Destruction

```bash
terraform destroy
```

## Utilisation dans GitLab CI/CD

Ce module est utilisé automatiquement dans `.gitlab-ci.yml` :

```yaml
deploy_staging:
  stage: deploy_staging
  image: hashicorp/terraform:latest
  script:
    - cd terraform/k8s-staging
    - terraform init
    - terraform apply -auto-approve \
        -var="docker_image=$CI_REGISTRY_IMAGE" \
        -var="docker_tag=$CI_COMMIT_SHORT_SHA" \
        -var="registry_user=$CI_REGISTRY_USER" \
        -var="registry_password=$CI_REGISTRY_PASSWORD"
```

Le kubeconfig est injecté via la variable `KUBE_CONFIG_STAGING` (base64).

## Ressources créées

1. **kubernetes_namespace.staging** - Namespace tp-devsecops-staging
2. **kubernetes_secret.gitlab_registry** - Secret pour pull d'images
3. **kubernetes_deployment.app** - Deployment avec 3 réplicas
4. **kubernetes_service.app** - Service LoadBalancer

## Troubleshooting

### Erreur "Unable to connect to cluster"

Vérifiez votre kubeconfig :
```bash
kubectl cluster-info
kubectl config current-context
```

### Pods en ImagePullBackOff

Vérifiez le secret :
```bash
kubectl get secret gitlab-registry-secret -n tp-devsecops-staging -o yaml
```

Vérifiez les credentials GitLab Container Registry.

### Service reste en <pending>

Si vous utilisez Minikube :
```bash
minikube tunnel
```

Pour les autres clusters, vérifiez que le LoadBalancer est supporté.

---

**Terraform + Kubernetes = Infrastructure as Code complète ! 🚀**
