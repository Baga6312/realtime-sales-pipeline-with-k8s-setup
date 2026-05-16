#!/bin/bash
set -e

echo "======================================"
echo "  realtime-sales-pipeline K8s Deploy"
echo "======================================"

# 1. Namespaces
echo "[1/8] Creating namespaces..."
kubectl apply -f namespaces/namespaces.yaml
sleep 2

# 2. Secrets
echo "[2/8] Applying secrets..."
kubectl apply -f bigdata/postgres/secret.yaml
kubectl apply -f wordpress/secret.yaml

# 3. ConfigMaps
echo "[3/8] Applying configmaps..."
kubectl apply -f bigdata/hadoop/configmap.yaml
kubectl apply -f bigdata/spark/configmap.yaml

# 4. PVCs
echo "[4/8] Creating persistent volumes..."
kubectl apply -f bigdata/postgres/pvc.yaml
kubectl apply -f bigdata/hadoop/namenode-pvc.yaml
kubectl apply -f bigdata/hadoop/datanode-pvc.yaml
kubectl apply -f bigdata/spark/notebooks-pvc.yaml
kubectl apply -f wordpress/pvc.yaml

# 5. Deployments
echo "[5/8] Deploying services..."
kubectl apply -f bigdata/postgres/deployment.yaml
kubectl apply -f bigdata/postgres/service.yaml
echo "Waiting for PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgres -n bigdata --timeout=120s

kubectl apply -f bigdata/hadoop/namenode-deployment.yaml
kubectl apply -f bigdata/hadoop/namenode-service.yaml
echo "Waiting for NameNode..."
kubectl wait --for=condition=ready pod -l app=namenode -n bigdata --timeout=120s

kubectl apply -f bigdata/hadoop/datanode-deployment.yaml
kubectl apply -f bigdata/hadoop/resourcemanager-deployment.yaml
kubectl apply -f bigdata/hadoop/resourcemanager-service.yaml
kubectl apply -f bigdata/hadoop/nodemanager-deployment.yaml

kubectl apply -f bigdata/spark/deployment.yaml
kubectl apply -f bigdata/spark/service.yaml

kubectl apply -f wordpress/deployment.yaml
kubectl apply -f wordpress/service.yaml

# 6. NetworkPolicy
echo "[6/8] Applying network policies..."
kubectl apply -f bigdata/networkpolicy.yaml

# 7. HPA
echo "[7/8] Applying autoscalers..."
kubectl apply -f bigdata/spark/hpa.yaml
kubectl apply -f bigdata/hadoop/datanode-hpa.yaml

# 8. Ingress
echo "[8/8] Setting up ingress..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
sleep 10
kubectl apply -f ingress/ingress.yaml

echo ""
echo "======================================"
echo "  Deployment Complete!"
echo "======================================"
echo ""
echo "Add to C:\\Windows\\System32\\drivers\\etc\\hosts:"
echo "127.0.0.1 jupyter.bigdata.local"
echo "127.0.0.1 hdfs.bigdata.local"
echo "127.0.0.1 yarn.bigdata.local"
echo "127.0.0.1 thrift.bigdata.local"
echo "127.0.0.1 wordpress.bigdata.local"
echo ""
echo "Services:"
echo "- Jupyter:    http://jupyter.bigdata.local"
echo "- HDFS UI:    http://hdfs.bigdata.local"
echo "- YARN UI:    http://yarn.bigdata.local"
echo "- WordPress:  http://wordpress.bigdata.local"
echo "- Power BI:   http://thrift.bigdata.local/cliservice"
kubectl get pods -n bigdata
kubectl get pods -n wordpress