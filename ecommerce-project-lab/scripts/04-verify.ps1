$ErrorActionPreference = 'Stop'
kubectl get nodes -o wide
kubectl get pods -n mini-shop -o wide
kubectl get svc,endpointslice -n mini-shop
kubectl get pods -n mini-shop -o custom-columns='NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName,IP:.status.podIP'
# Match the frontend label so this diagnostic Pod is allowed by the demo NetworkPolicy.
# Create, wait, exec, then delete explicitly so the Pod network is ready before wget starts.
kubectl delete pod network-check -n mini-shop --ignore-not-found
Start-Sleep -Seconds 2
kubectl run network-check -n mini-shop --labels=app.kubernetes.io/name=frontend --restart=Never --image=busybox:1.36 --command -- sleep 60
kubectl wait --for=condition=Ready pod/network-check -n mini-shop --timeout=120s
try { kubectl exec -n mini-shop network-check -- wget -qO- http://backend-service:8000/api/products }
finally { kubectl delete pod network-check -n mini-shop --ignore-not-found }
Invoke-WebRequest -UseBasicParsing http://localhost:8080 | Select-Object -ExpandProperty StatusCode
Invoke-WebRequest -UseBasicParsing http://localhost:8080/api/products | Select-Object -ExpandProperty Content