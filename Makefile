REGISTRY=localhost:5000
SPARK_IMAGE=$(REGISTRY)/spark:latest
WORDPRESS_IMAGE=$(REGISTRY)/wordpress:latest

.PHONY: all build push deploy teardown

all: build push deploy

# Build images
build:
	docker build -t $(SPARK_IMAGE) ./spark
	docker build -t $(WORDPRESS_IMAGE) ./wordpress -f ./wordpress/Dockerfile-wordpress

# Push to local registry
push:
	docker push $(SPARK_IMAGE)
	docker push $(WORDPRESS_IMAGE)

# Deploy to Kubernetes
deploy:
	kubectl apply -f k8s/namespaces/
	kubectl apply -f k8s/registry/
	kubectl apply -f k8s/bigdata/postgres/
	kubectl apply -f k8s/bigdata/hadoop/
	kubectl apply -f k8s/bigdata/spark/
	kubectl apply -f k8s/wordpress/
	kubectl apply -f k8s/ingress/

# Teardown
teardown:
	kubectl delete -f k8s/ingress/ --ignore-not-found
	kubectl delete -f k8s/wordpress/ --ignore-not-found
	kubectl delete -f k8s/bigdata/ --ignore-not-found
	kubectl delete -f k8s/registry/ --ignore-not-found
	kubectl delete -f k8s/namespaces/ --ignore-not-found

# Check status
status:
	kubectl get pods -n bigdata
	kubectl get pods -n wordpress

# Logs
logs-spark:
	kubectl logs -f deployment/spark -n bigdata

logs-postgres:
	kubectl logs -f deployment/postgres -n bigdata

logs-wordpress:
	kubectl logs -f deployment/wordpress -n wordpress
	