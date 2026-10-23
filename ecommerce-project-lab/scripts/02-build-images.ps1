param([string]$ClusterName = 'mini-shop')
$ErrorActionPreference = 'Stop'
docker build -t mini-shop-backend:local ./app/backend
docker build -t mini-shop-frontend:local ./app/frontend
k3d image import mini-shop-backend:local mini-shop-frontend:local -c $ClusterName
docker images --filter=reference='mini-shop-backend:local' --filter=reference='mini-shop-frontend:local'