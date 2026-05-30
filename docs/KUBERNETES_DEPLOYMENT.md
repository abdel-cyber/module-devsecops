# 🚀 Guide de Déploiement Kubernetes

## Architecture

L'application est déployée sur **2 clusters Kubernetes** distincts :

### 🔵 Cluster 1 - STAGING
- **Namespace** : `tp-devsecops-staging`
- **Pods** : 3 réplicas de l'application
- **Environnement** : Tests et validation
- **Branche GitLab** : `develop`
- **Image Docker** : Tag du commit SHA

### 🟢 Cluster 2 - PRODUCTION
- **Namespace** : `tp-devsecops-production`
- **Pods** : 3 réplicas de l'application
- **Environnement** : Production (haute disponibilité)
- **Branche GitLab** : `main`
- **Image Docker** : Tag `latest`

---

## 📦 Composants Kubernetes Créés

### Pour chaque cluster :
1. **Namespace** - Isolation des ressources
2. **Deployment** - 3 pods avec stratégie RollingUpdate
3. **Service** - LoadBalancer pour accès externe
4. **Secret** - Credentials GitLab Container Registry

---

## 🔧 Prérequis

### 1. Clusters Kubernetes
Vous avez besoin de 2 clusters Kubernetes fonctionnels :
- Minikube (local)
- Docker Desktop Kubernetes
- K3s
- AKS / EKS / GKE (cloud)

### 2. kubectl installé
```bash
# Vérifier l'installation
kubectl version --client
```

### 3. Contextes kubectl configurés
```bash
# Lister les contextes
kubectl config get-contexts

# Exemple de contextes :
# staging-context  -> Cluster 1 (Staging)
# production-context  -> Cluster 2 (Production)
```

---

## 🚀 Déploiement Manuel (pour tests locaux)

### Option A : Déploiement STAGING (Cluster 1)

#### 1. Basculer vers le contexte staging
```bash
kubectl config use-context staging-context
```

#### 2. Créer le namespace
```bash
kubectl apply -f kubernetes/staging/namespace.yaml
```

#### 3. Créer le secret GitLab Registry
```bash
kubectl create secret docker-registry gitlab-registry-secret \
  --docker-server=registry.gitlab.com \
  --docker-username=abdelmouiz99 \
  --docker-password=VOTRE_DEPLOY_TOKEN \
  --docker-email=votre-email@example.com \
  --namespace=tp-devsecops-staging
```

#### 4. Déployer l'application (3 pods)
```bash
kubectl apply -f kubernetes/staging/deployment.yaml
```

#### 5. Exposer le service
```bash
kubectl apply -f kubernetes/staging/service.yaml
```

#### 6. Vérifier le déploiement
```bash
# Voir les pods (3 pods doivent être en Running)
kubectl get pods -n tp-devsecops-staging

# Voir le service
kubectl get service -n tp-devsecops-staging

# Logs d'un pod
kubectl logs -f deployment/devsecops-app -n tp-devsecops-staging

# Décrire un pod
kubectl describe pod POD_NAME -n tp-devsecops-staging
```

#### 7. Accéder à l'application
```bash
# Si LoadBalancer
kubectl get service devsecops-app-service -n tp-devsecops-staging
# Utilisez l'EXTERNAL-IP affichée

# Si Minikube
minikube service devsecops-app-service -n tp-devsecops-staging

# Si NodePort (modifier service.yaml)
kubectl get nodes -o wide  # Récupérer IP du node
# Accéder à http://NODE_IP:NODE_PORT
```

---

### Option B : Déploiement PRODUCTION (Cluster 2)

#### 1. Basculer vers le contexte production
```bash
kubectl config use-context production-context
```

#### 2. Créer le namespace
```bash
kubectl apply -f kubernetes/production/namespace.yaml
```

#### 3. Créer le secret GitLab Registry
```bash
kubectl create secret docker-registry gitlab-registry-secret \
  --docker-server=registry.gitlab.com \
  --docker-username=abdelmouiz99 \
  --docker-password=VOTRE_DEPLOY_TOKEN \
  --docker-email=votre-email@example.com \
  --namespace=tp-devsecops-production
```

#### 4. Déployer l'application (3 pods)
```bash
kubectl apply -f kubernetes/production/deployment.yaml
```

#### 5. Exposer le service
```bash
kubectl apply -f kubernetes/production/service.yaml
```

#### 6. Vérifier le déploiement
```bash
# Voir les 3 pods en production
kubectl get pods -n tp-devsecops-production -o wide

# Voir le service
kubectl get service -n tp-devsecops-production

# Suivre le rollout
kubectl rollout status deployment/devsecops-app -n tp-devsecops-production
```

---

## 🤖 Déploiement Automatique via GitLab CI/CD

### Configuration GitLab Variables

Allez sur : `https://gitlab.com/abdelmouiz99/tp-devsecops-app/-/settings/ci_cd`

Ajoutez ces variables :

| Variable | Description | Masked | Protected |
|----------|-------------|--------|-----------|
| `KUBE_CONFIG_STAGING` | Kubeconfig du cluster staging (encodé en base64) | ✅ | ❌ |
| `KUBE_CONFIG_PRODUCTION` | Kubeconfig du cluster production (encodé en base64) | ✅ | ✅ |

### Comment obtenir KUBE_CONFIG encodé en base64 ?

#### Pour Staging :
```bash
# Basculer sur le contexte staging
kubectl config use-context staging-context

# Exporter et encoder
kubectl config view --flatten --minify | base64 -w 0

# Copiez la sortie dans la variable KUBE_CONFIG_STAGING
```

#### Pour Production :
```bash
# Basculer sur le contexte production
kubectl config use-context production-context

# Exporter et encoder
kubectl config view --flatten --minify | base64 -w 0

# Copiez la sortie dans la variable KUBE_CONFIG_PRODUCTION
```

### Déclenchement du Pipeline

#### Déploiement Staging :
1. Poussez sur la branche `develop`
2. Allez sur : `https://gitlab.com/abdelmouiz99/tp-devsecops-app/-/pipelines`
3. Cliquez sur **Play (▶️)** pour le job `deploy_staging`
4. Attendez 2-3 minutes
5. L'application sera déployée avec 3 pods

#### Déploiement Production :
1. Mergez `develop` dans `main`
2. Allez sur le pipeline de `main`
3. Cliquez sur **Play (▶️)** pour le job `deploy_production`
4. Attendez 2-3 minutes
5. L'application sera déployée avec 3 pods en haute disponibilité

---

## 🔍 Commandes de Monitoring

### Staging

```bash
# Contexte
kubectl config use-context staging-context

# Tous les pods (doit afficher 3 pods)
kubectl get pods -n tp-devsecops-staging

# Pods avec détails (CPU, Mémoire)
kubectl top pods -n tp-devsecops-staging

# Logs en temps réel
kubectl logs -f -l app=devsecops-app -n tp-devsecops-staging

# Événements
kubectl get events -n tp-devsecops-staging --sort-by='.lastTimestamp'

# Statut du deployment
kubectl rollout history deployment/devsecops-app -n tp-devsecops-staging

# Scaling manuel (changer le nombre de pods)
kubectl scale deployment devsecops-app --replicas=5 -n tp-devsecops-staging
```

### Production

```bash
# Contexte
kubectl config use-context production-context

# Tous les pods (doit afficher 3 pods)
kubectl get pods -n tp-devsecops-production -o wide

# Pods avec métriques
kubectl top pods -n tp-devsecops-production

# Logs agrégés de tous les pods
kubectl logs -f -l app=devsecops-app -n tp-devsecops-production

# Health checks
kubectl get endpoints -n tp-devsecops-production

# Rollback en cas de problème
kubectl rollout undo deployment/devsecops-app -n tp-devsecops-production
```

---

## 🧪 Tests

### Test de santé de l'application

```bash
# Récupérer l'IP externe (staging)
EXTERNAL_IP=$(kubectl get service devsecops-app-service -n tp-devsecops-staging -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test endpoint /health
curl http://$EXTERNAL_IP/health

# Test endpoint principal
curl http://$EXTERNAL_IP/
```

### Test de charge (vérifier les 3 pods)

```bash
# Installer hey (load testing)
go install github.com/rakyll/hey@latest

# Test de charge avec 100 requêtes
hey -n 100 -c 10 http://$EXTERNAL_IP/

# Vérifier que les 3 pods répondent
kubectl logs -l app=devsecops-app -n tp-devsecops-staging --tail=10
```

---

## 🚨 Troubleshooting

### Pods ne démarrent pas

```bash
# Voir les erreurs
kubectl describe pod POD_NAME -n tp-devsecops-staging

# Problème fréquent : ImagePullBackOff
# Solution : Vérifier le secret gitlab-registry-secret
kubectl get secret gitlab-registry-secret -n tp-devsecops-staging
kubectl describe secret gitlab-registry-secret -n tp-devsecops-staging
```

### Service inaccessible

```bash
# Vérifier le service
kubectl get service -n tp-devsecops-staging

# Vérifier les endpoints (doivent pointer vers 3 pods)
kubectl get endpoints devsecops-app-service -n tp-devsecops-staging

# Si LoadBalancer reste en <pending>
# Sur Minikube :
minikube tunnel

# Sur clusters cloud, vérifier les quotas de LoadBalancer
```

### Rollout bloqué

```bash
# Voir le statut détaillé
kubectl rollout status deployment/devsecops-app -n tp-devsecops-staging

# Annuler le rollout
kubectl rollout undo deployment/devsecops-app -n tp-devsecops-staging

# Redémarrer tous les pods
kubectl rollout restart deployment/devsecops-app -n tp-devsecops-staging
```

---

## 🧹 Nettoyage

### Supprimer le déploiement Staging

```bash
kubectl delete -f kubernetes/staging/
kubectl delete namespace tp-devsecops-staging
```

### Supprimer le déploiement Production

```bash
kubectl delete -f kubernetes/production/
kubectl delete namespace tp-devsecops-production
```

---

## 📊 Architecture Technique

```
┌─────────────────────────────────────────────────────────────┐
│                     GitLab CI/CD Pipeline                    │
│  test → security → build → deploy_staging → deploy_production│
└─────────────────────────────────────────────────────────────┘
                              │
                              ├─────────────────┬──────────────────┐
                              │                 │                  │
                    ┌─────────▼────────┐ ┌──────▼──────────┐     │
                    │  Container        │ │   Container     │     │
                    │  Registry         │ │   Registry      │     │
                    │  (GitLab)         │ │   (GitLab)      │     │
                    └─────────┬────────┘ └──────┬──────────┘     │
                              │                 │                  │
                    ┌─────────▼────────┐ ┌──────▼──────────┐     │
                    │  CLUSTER 1        │ │   CLUSTER 2     │     │
                    │  STAGING          │ │  PRODUCTION     │     │
                    │                   │ │                 │     │
                    │  Namespace:       │ │  Namespace:     │     │
                    │  tp-devsecops-    │ │  tp-devsecops-  │     │
                    │  staging          │ │  production     │     │
                    │                   │ │                 │     │
                    │  ┌──────────┐    │ │  ┌──────────┐  │     │
                    │  │ Pod 1    │    │ │  │ Pod 1    │  │     │
                    │  │ App:3000 │    │ │  │ App:3000 │  │     │
                    │  └──────────┘    │ │  └──────────┘  │     │
                    │  ┌──────────┐    │ │  ┌──────────┐  │     │
                    │  │ Pod 2    │    │ │  │ Pod 2    │  │     │
                    │  │ App:3000 │    │ │  │ App:3000 │  │     │
                    │  └──────────┘    │ │  └──────────┘  │     │
                    │  ┌──────────┐    │ │  ┌──────────┐  │     │
                    │  │ Pod 3    │    │ │  │ Pod 3    │  │     │
                    │  │ App:3000 │    │ │  │ App:3000 │  │     │
                    │  └──────────┘    │ │  └──────────┘  │     │
                    │       │          │ │       │        │     │
                    │  ┌────▼─────┐   │ │  ┌────▼─────┐ │     │
                    │  │ Service  │   │ │  │ Service  │ │     │
                    │  │ LB:80    │   │ │  │ LB:80    │ │     │
                    │  └──────────┘   │ │  └──────────┘ │     │
                    └─────────────────┘ └────────────────┘     │
                              │                 │                  │
                              ▼                 ▼                  │
                     http://staging-ip  http://prod-ip            │
```

---

## 🏆 Avantages de Kubernetes vs AWS/Azure

| Critère | Kubernetes | AWS EC2 / Azure App |
|---------|-----------|---------------------|
| **Haute Disponibilité** | ✅ 3 pods répartis | ❌ 1 instance unique |
| **Auto-scaling** | ✅ HPA natif | ⚠️ Configuration complexe |
| **Rolling Updates** | ✅ Zero downtime | ❌ Downtime possible |
| **Portabilité** | ✅ Multi-cloud | ❌ Lock-in cloud |
| **Coût (dev)** | ✅ Gratuit (local) | ❌ Facturation continue |
| **Monitoring** | ✅ Kubectl intégré | ⚠️ Tools externes |

---

## 📚 Ressources

- [Documentation Kubernetes](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [GitLab Kubernetes Integration](https://docs.gitlab.com/ee/user/clusters/agent/)

---

**✅ Configuration terminée ! Vos 2 clusters Kubernetes avec 3 pods chacun sont prêts au déploiement !** 🚀
