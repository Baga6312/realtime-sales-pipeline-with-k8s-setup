SPARK_IMAGE=spark-bigdata:latest
WORDPRESS_IMAGE=wordpress-bigdata:latest

.PHONY: all build deploy teardown status logs-spark logs-postgres logs-wordpress

all: build deploy

# Build images
build:
	docker build -t $(SPARK_IMAGE) ./spark
	docker build -t $(WORDPRESS_IMAGE) ./wordpress -f ./wordpress/Dockerfile-wordpress

# Deploy to Kubernetes
deploy:
	kubectl apply -f k8s/namespaces/
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