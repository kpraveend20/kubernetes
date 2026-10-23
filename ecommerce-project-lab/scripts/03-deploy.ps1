$ErrorActionPreference = 'Stop'
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/10-backend.yaml
kubectl rollout status deployment/backend -n mini-shop --timeout=180s
kubectl apply -f k8s/20-frontend.yaml
kubectl rollout status deployment/frontend -n mini-shop --timeout=180s
kubectl apply -f k8s/30-network-policy.yaml
kubectl get all -n mini-shop