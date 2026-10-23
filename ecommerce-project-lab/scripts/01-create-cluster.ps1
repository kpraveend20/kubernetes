param([string]$ClusterName = 'mini-shop')
$ErrorActionPreference = 'Stop'
$K3sImage = 'rancher/k3s:v1.33.5-k3s1'
if (-not (Get-Command k3d -ErrorAction SilentlyContinue)) { throw 'k3d is required. Install k3d, then rerun this script.' }
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw 'Docker Desktop is required and must be running.' }
if ((k3d cluster list -o json | ConvertFrom-Json | Where-Object { $_.name -eq $ClusterName })) { Write-Host "Cluster $ClusterName already exists." } else {
  # Pin a k3s release compatible with Docker Desktop environments exposing cgroup v1.
  k3d cluster create $ClusterName --servers 1 --agents 2 --image $K3sImage --port '8080:30080@loadbalancer' --wait
}
$apiPort = (docker port "k3d-$ClusterName-serverlb" 6443/tcp).Split(':')[-1]
kubectl config set-cluster "k3d-$ClusterName" --server="https://127.0.0.1:$apiPort" | Out-Null
kubectl config use-context "k3d-$ClusterName"
$agentNodes = @(kubectl get nodes -o name | Where-Object { $_ -match '-agent-' })
if ($agentNodes.Count -ne 2) { throw "Expected exactly two k3d agent nodes, found $($agentNodes.Count)." }
foreach ($node in $agentNodes) { kubectl label $node lab-role=app --overwrite | Out-Null }
kubectl get nodes --show-labels