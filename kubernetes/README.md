# Kubernetes Manifests

Ce dossier contient les manifestes Kubernetes pour déployer l'application sur 2 clusters distincts.

## Structure

```
kubernetes/
├── staging/                    # Cluster 1 - STAGING
│   ├── namespace.yaml         # Namespace tp-devsecops-staging
│   ├── deployment.yaml        # 3 pods (replicas: 3)
│   └── service.yaml           # LoadBalancer port 80 → 3000
│
├── production/                # Cluster 2 - PRODUCTION
│   ├── namespace.yaml         # Namespace tp-devsecops-production
│   ├── deployment.yaml        # 3 pods (replicas: 3)
│   └── service.yaml           # LoadBalancer port 80 → 3000
│
└── create-registry-secret.sh  # Script pour créer les secrets Docker Registry
```

## Caractéristiques

### Staging (Cluster 1)
- **3 pods** avec l'application Node.js
- **RollingUpdate** : maxSurge=1, maxUnavailable=1
- **Resources** : 128Mi-256Mi RAM, 100m-200m CPU
- **Health checks** : /health endpoint
- **Image** : Tag du commit SHA (`$CI_COMMIT_SHORT_SHA`)

### Production (Cluster 2)
- **3 pods** avec l'application Node.js
- **RollingUpdate** : maxSurge=1, maxUnavailable=0 (zero downtime)
- **Resources** : 256Mi-512Mi RAM, 200m-500m CPU
- **Health checks** : /health endpoint (délais plus longs)
- **Image** : Tag `latest`

## Déploiement Rapide

### Staging
```bash
kubectl apply -f staging/namespace.yaml
kubectl apply -f staging/deployment.yaml
kubectl apply -f staging/service.yaml
kubectl get pods -n tp-devsecops-staging
```

### Production
```bash
kubectl apply -f production/namespace.yaml
kubectl apply -f production/deployment.yaml
kubectl apply -f production/service.yaml
kubectl get pods -n tp-devsecops-production
```

## Documentation Complète

Voir [../docs/KUBERNETES_DEPLOYMENT.md](../docs/KUBERNETES_DEPLOYMENT.md) pour :
- Configuration des clusters
- Variables GitLab CI/CD
- Commandes de monitoring
- Troubleshooting
- Tests de charge

## Variables d'Environnement

Les deployments utilisent ces variables :
- `NODE_ENV` : "staging" ou "production"
- `PORT` : "3000"

## Secrets

Les pods utilisent un secret pour accéder au GitLab Container Registry :
```bash
kubectl create secret docker-registry gitlab-registry-secret \
  --docker-server=registry.gitlab.com \
  --docker-username=abdelmouiz99 \
  --docker-password=VOTRE_DEPLOY_TOKEN \
  --namespace=tp-devsecops-staging
```

## Monitoring

```bash
# Voir les 3 pods
kubectl get pods -n tp-devsecops-staging

# Logs en temps réel
kubectl logs -f -l app=devsecops-app -n tp-devsecops-staging

# Métriques
kubectl top pods -n tp-devsecops-staging
```

---

**Configuration Kubernetes prête ! 🚀**
