# Kubernetes Workload Controllers Practice

## Files
- 00-namespace.yaml
- 01-deployment.yaml
- 02-statefulset.yaml
- 03-daemonset.yaml

## Cluster setup
```powershell
minikube version
docker version
kubectl version --client

minikube start --driver=docker
minikube status
kubectl get nodes
kubectl cluster-info
```

## Namespace
```powershell
kubectl apply -f .\00-namespace.yaml
kubectl get ns
kubectl get namespace workload-lab
```

## Deployment
```powershell
kubectl apply -f .\01-deployment.yaml
kubectl get deployment -n workload-lab
kubectl get pods -n workload-lab -o wide
kubectl describe deployment shop-web -n workload-lab

kubectl scale deployment shop-web -n workload-lab --replicas=5
kubectl get pods -n workload-lab
kubectl rollout status deployment/shop-web -n workload-lab
kubectl rollout history deployment/shop-web -n workload-lab
kubectl rollout undo deployment/shop-web -n workload-lab

kubectl delete pod shop-web-<pod-index> -n workload-lab
kubectl get pods -n workload-lab

kubectl get service -n workload-lab
kubectl port-forward service/shop-web -n workload-lab 8080:80
```

Open: http://localhost:8080

## StatefulSet
```powershell
kubectl apply -f .\02-statefulset.yaml
kubectl get statefulset -n workload-lab
kubectl get pods -n workload-lab -o wide
kubectl get pvc -n workload-lab
kubectl get pv
kubectl describe statefulset notebooks -n workload-lab
kubectl get service -n workload-lab

kubectl delete pod notebooks-0 -n workload-lab
kubectl get pods -n workload-lab

kubectl exec -it notebooks-0 -n workload-lab -- sh
# inside pod:
echo "StatefulSet practice" > /usr/share/nginx/html/index.html
exit

kubectl delete pod notebooks-0 -n workload-lab
kubectl get pods -n workload-lab
kubectl exec -it notebooks-0 -n workload-lab -- cat /usr/share/nginx/html/index.html
```

## DaemonSet
```powershell
kubectl apply -f .\03-daemonset.yaml
kubectl get daemonset -n workload-lab
kubectl get pods -n workload-lab -o wide
kubectl describe daemonset node-reporter -n workload-lab
kubectl logs -l app=node-reporter -n workload-lab
```

## Useful commands
```powershell
kubectl get all -n workload-lab
kubectl get pods -n workload-lab
kubectl describe pod <pod-name> -n workload-lab
kubectl logs <pod-name> -n workload-lab
kubectl exec -it <pod-name> -n workload-lab -- sh
kubectl get events --sort-by=.metadata.creationTimestamp -n workload-lab
kubectl get pvc -n workload-lab
kubectl get storageclass
kubectl get pods -n workload-lab -w
kubectl apply --dry-run=client -f .\01-deployment.yaml
```

## Git
```powershell
git status
git add .
git commit -m "Add Kubernetes workload controllers project"
git log --oneline
git remote -v
git push -u origin main
```

## Cleanup
```powershell
kubectl delete -f .\03-daemonset.yaml
kubectl delete -f .\02-statefulset.yaml
kubectl delete -f .\01-deployment.yaml
kubectl delete -f .\00-namespace.yaml
```

## Quick memory
```text
Deployment  -> Stateless app
StatefulSet -> Stable identity + persistent storage
DaemonSet   -> One pod on each eligible node
```