# Script pour créer le secret d'accès au GitLab Container Registry
# À exécuter sur chaque cluster Kubernetes (staging et production)

# STAGING
kubectl create secret docker-registry gitlab-registry-secret \
  --docker-server=registry.gitlab.com \
  --docker-username=abdelmouiz99 \
  --docker-password=VOTRE_DEPLOY_TOKEN \
  --docker-email=votre-email@example.com \
  --namespace=tp-devsecops-staging

# PRODUCTION
kubectl create secret docker-registry gitlab-registry-secret \
  --docker-server=registry.gitlab.com \
  --docker-username=abdelmouiz99 \
  --docker-password=VOTRE_DEPLOY_TOKEN \
  --docker-email=votre-email@example.com \
  --namespace=tp-devsecops-production
