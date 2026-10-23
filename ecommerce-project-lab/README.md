## Lab 1 – Kubernetes Cluster

### Objective

Create a local Kubernetes cluster using k3d and understand
the control-plane and worker nodes.

### Commands

```powershell
kubectl get nodes -o wide
kubectl get nodes --show-labels
```

## Lab 2 – Build Docker Images

### Objective

Build the backend and frontend Docker images locally
and make them available to the k3d cluster.

### Commands

```powershell
.\scripts\02-build-images.ps1
docker images
```

## Lab 3 – Deploy Application

### Objective

Deploy the backend and frontend applications into
the `mini-shop` namespace.

### Commands

```powershell
kubectl get all -n mini-shop
kubectl get pods -n mini-shop -o wide
```

## Lab 4 – Access E-Commerce Application

### Objective

Access the frontend application from the local machine.

### URL

http://localhost:8080

### Architecture

```text
Browser
   ↓
localhost:8080
   ↓
k3d Load Balancer
   ↓
NodePort 30080
   ↓
Frontend Pod
```

## Lab 5 – Kubernetes Service DNS

### Objective

Test communication between the frontend-side Pod
and the backend Service using Kubernetes DNS.

### Commands

```powershell
kubectl exec -n mini-shop api-check -- nslookup backend-service

kubectl exec -n mini-shop api-check -- wget -qO- http://backend-service:8000/api/products
```

## Troubleshooting: `CrashLoopBackOff` and watchstream errors

### What happened

The `mini-shop` pods repeatedly became unhealthy, and `kubectl` sometimes
reported an API watchstream error similar to:

```text
InternalError: unable to decode an event from the watch stream:
http2: client connection lost
```

`CrashLoopBackOff` is Kubernetes' status for a container that has exited or
been restarted repeatedly. It is not, by itself, the root cause. The watchstream
message is a separate symptom: the client lost its connection to an
unresponsive Kubernetes API server.

### Root causes found in this cluster

1. **Host CPU saturation.** Windows reported CPU usage at 100%. The k3d nodes
   also showed sustained CPU pressure. API requests, DNS, and pod health probes
   consequently timed out. The backend's liveness probe used Kubernetes'
   default one-second timeout, so it was too sensitive to those delays.
2. **The backend was restarted after failed liveness probes.** Pod events showed
   failed health checks followed by kubelet restarting the backend. Its exit
   code was 137, but the container's OOM-kill counter was zero. In this case,
   that exit code alone did not establish that the memory limit caused the
   failure.
3. **The frontend exited when its Nginx configuration could not resolve the
   backend Service during startup.** Nginx originally resolved that Service
   name while loading its configuration; a temporary DNS/control-plane outage
   made Nginx exit.
4. **A cluster restart exposed an IP-address mismatch.** The Docker bridge
   assigned a different IP to the k3d server than the cluster expected. K3s
   then failed to initialize networking. The cluster recovered after the
   original node IP assignments were restored.

### Changes applied

- Added startup probes and increased readiness/liveness probe timeouts to five
  seconds, allowing more time for containers to respond during temporary CPU
  pressure.
- Raised the backend CPU request/limit to `100m`/`500m` and the frontend to
  `50m`/`250m`, allowing short CPU bursts. These settings do not add CPU
  capacity to the host.
- Configured Nginx to resolve the backend Service when handling API requests,
  rather than requiring DNS to succeed when Nginx starts.
- Set the backend rolling update strategy to replace at most one replica at a
  time, avoiding temporary CPU spikes from starting extra replicas.
- Restored the existing k3d nodes to their expected Docker network IPs. Do not
  delete and recreate the cluster as a first troubleshooting step; that can
  remove cluster state and is not necessary to investigate a transient
  networking issue.

### How to diagnose it

Run these commands in PowerShell:

```powershell
kubectl get nodes -o wide
kubectl get pods -n mini-shop -o wide
kubectl describe pod <pod-name> -n mini-shop
kubectl logs <pod-name> -n mini-shop --previous
kubectl get events -n mini-shop --sort-by=.lastTimestamp
docker stats --no-stream
```

In `kubectl describe pod`, check the last termination reason and the events.
Repeated `Liveness probe failed` messages followed by `Killing` indicate that
the probe caused the restart. `OOMKilled` and a nonzero OOM-kill count indicate
a memory kill; do not infer an OOM solely from exit code 137. If multiple pods
and the API are timing out together, check host CPU and Docker node usage.

### Recovery steps

1. Open Windows Task Manager, sort by CPU usage, and close or pause unnecessary
   CPU-heavy applications. Increasing pod CPU limits cannot overcome a
   saturated host.
2. Check node and pod health:

   ```powershell
   kubectl get nodes
   kubectl get pods -n mini-shop
   ```

   Nodes should be `Ready`; the backend and frontend pods should be `Running`
   and `1/1` ready.
3. Verify the application and its backend API route:

   ```powershell
   Invoke-WebRequest http://localhost:8080/api/products
   ```

   A successful response has HTTP status 200 and returns product JSON.
4. If the API is unavailable, check that Docker Desktop and the k3d cluster
   are running before retrying `kubectl`. You can stop the cluster when it is
   not in use and start it later:

   ```powershell
   k3d cluster stop mini-shop
   k3d cluster start mini-shop
   ```

   After starting it, verify node and pod health again. If nodes do not become
   `Ready`, inspect the k3d node addresses and K3s logs before changing Docker
   network settings.

The application was verified with all three nodes `Ready`, both backend
replicas and the frontend pod `1/1` ready, and an HTTP 200 response from
`http://localhost:8080/api/products`. Host CPU saturation can still cause
intermittent delays, so reducing host CPU usage remains important.
