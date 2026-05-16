#!/bin/bash
echo "Tearing down realtime-sales-pipeline..."

kubectl delete -f ingress/ --ignore-not-found
kubectl delete -f bigdata/spark/ --ignore-not-found
kubectl delete -f bigdata/hadoop/ --ignore-not-found
kubectl delete -f bigdata/postgres/ --ignore-not-found
kubectl delete -f wordpress/ --ignore-not-found
kubectl delete -f bigdata/networkpolicy.yaml --ignore-not-found
kubectl delete -f namespaces/namespaces.yaml --ignore-not-found

echo "Done. All resources removed."