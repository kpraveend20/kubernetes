param([string]$ClusterName = 'mini-shop')
$ErrorActionPreference = 'Stop'
kubectl delete namespace mini-shop --ignore-not-found
if (Get-Command k3d -ErrorAction SilentlyContinue) { k3d cluster delete $ClusterName }