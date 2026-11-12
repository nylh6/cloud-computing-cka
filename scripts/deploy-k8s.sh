#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

echo "=================================================="
echo " Deploying Cloud App to Kubernetes Cluster"
echo "=================================================="

echo ""
echo ">> 1. Creating Namespace..."
kubectl apply -f k8s/00-namespace.yaml

echo ""
echo ">> 2. Applying ConfigMap & Secret..."
kubectl apply -f k8s/01-configmap-secret.yaml

echo ""
echo ">> 3. Deploying MySQL Database..."
kubectl apply -f k8s/02-mysql.yaml

echo "Waiting for MySQL Pod to become Ready..."
kubectl rollout status deployment/mysql -n cloud-app --timeout=120s

echo ""
echo ">> 4. Running Database Migrations Job..."
kubectl delete job db-migration-job -n cloud-app --ignore-not-found=true
kubectl apply -f k8s/03-migration-job.yaml
kubectl wait --for=condition=complete job/db-migration-job -n cloud-app --timeout=120s

echo ""
echo ">> 5. Deploying Backend API..."
kubectl apply -f k8s/04-backend.yaml
kubectl rollout status deployment/backend -n cloud-app --timeout=120s

echo ""
echo ">> 6. Deploying Frontend Web..."
kubectl apply -f k8s/05-frontend.yaml
kubectl rollout status deployment/frontend -n cloud-app --timeout=120s

echo ""
echo "=================================================="
echo " Deployment Completed Successfully!"
echo " Status of Pods and Services in namespace 'cloud-app':"
echo "=================================================="
kubectl get pods,svc -n cloud-app -o wide
