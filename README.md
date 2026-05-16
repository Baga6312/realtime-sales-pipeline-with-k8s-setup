# realtime-sales-pipeline

A production-grade Big Data pipeline built from scratch, designed to collect, 
process, store, and visualize sales data in real time.

## Architecture

```
WordPress (CF7) → PostgreSQL → Apache Spark (ETL) → HDFS → Hive Metastore → Thrift Server → Power BI
```

## Stack

| Component | Technology |
|-----------|-----------|
| Data Collection | WordPress + Contact Form 7 |
| Database | PostgreSQL 15 |
| Distributed Storage | Apache Hadoop 3.2 (HDFS) |
| Processing | Apache Spark 3.5.8 |
| Metastore | Hive Metastore (via PostgreSQL) |
| Visualization | Power BI Desktop |
| Containerization | Docker + Docker Compose |
| Orchestration | Kubernetes (Docker Desktop) |
| Notebooks | Jupyter |

## Features

- Real-time sales data collection via WordPress forms
- Automated ETL pipeline: WordPress DB → HDFS → Hive Metastore
- Star schema data modeling (fact_ventes, dim_produits, dim_geographie, dim_temps)
- Multi-currency support with TND conversion
- Power BI connected via Apache Thrift Server (HTTP mode)
- Full Docker Compose stack with persistence
- Kubernetes manifests with Namespaces, Secrets, ConfigMaps, PVCs, 
  Deployments, Services, Ingress, NetworkPolicy, HPA
- YARN cluster management with job tracking

## Quick Start

### Docker Compose
```bash
docker compose up -d
```

Services:
- Jupyter: http://localhost:8888
- HDFS UI: http://localhost:9870
- YARN UI: http://localhost:8088
- WordPress: http://localhost:8081
- Power BI: connect to http://127.0.0.1:10001/cliservice

### Kubernetes
```bash
kubectl apply -f namespaces/
kubectl apply -f bigdata/
kubectl apply -f wordpress/
kubectl apply -f ingress/
```

## ETL Pipeline

Run from Jupyter notebook:

```python
from pyspark.sql import SparkSession, functions as F

spark = SparkSession.builder \
    .appName("ETL-WordPress-to-HDFS") \
    .master("local[*]") \
    .config("spark.sql.catalogImplementation", "hive") \
    .enableHiveSupport() \
    .getOrCreate()

df = spark.read.format("jdbc") \
    .option("url", "jdbc:postgresql://postgres:5432/wordpress") \
    .option("dbtable", "sales_data") \
    .option("user", "hiveuser") \
    .option("password", "hivepassword") \
    .option("driver", "org.postgresql.Driver") \
    .load()

df.write.mode("overwrite").csv("hdfs://namenode:9000/data/sales/raw", header=True)
df.write.mode("overwrite").saveAsTable("wordpress_sales")
```

## Data Model

```
fact_ventes
├── transaction_id
├── produit → dim_produits
├── region  → dim_geographie  
├── date    → dim_temps
├── quantite
├── prix_tnd
├── devise
└── chiffre_affaires

dim_produits        dim_geographie      dim_temps
├── produit_id      ├── region_id       ├── temps_id
└── produit         └── region          ├── date
                                        ├── annee
                                        ├── mois
                                        └── jour
```

## Kubernetes Architecture

```
Namespaces: bigdata | wordpress | monitoring | ingress-nginx

bigdata/
├── postgres    (1 replica, 5Gi PVC)
├── namenode    (1 replica, 10Gi PVC)
├── datanode    (1-3 replicas, HPA, 20Gi PVC)
├── resourcemanager (1 replica)
├── nodemanager (1 replica)
└── spark       (1-5 replicas, HPA, 5Gi PVC)

wordpress/
└── wordpress   (1 replica, 5Gi PVC)

Security:
├── NetworkPolicy (namespace isolation)
├── Secrets (credentials)
└── RBAC (ServiceAccount + Roles)

Ingress:
├── jupyter.bigdata.local  → Spark:8888
├── hdfs.bigdata.local     → NameNode:9870
├── yarn.bigdata.local     → ResourceManager:8088
├── thrift.bigdata.local   → Spark:10001
└── wordpress.bigdata.local → WordPress:80
```

## Project Structure

```
realtime-sales-pipeline/
├── docker-compose.yml
├── hadoop.env
├── spark/
│   ├── hive-site.xml
│   └── start-spark.sh
├── wordpress/
│   ├── Dockerfile-wordpress
│   ├── entrypoint.sh
│   ├── pg4wp.zip
│   └── sales-collector.php
├── postgres/
│   └── init-postgres.sh
├── notebooks/
│   └── etl_pipeline.ipynb
├── bigdata/
│   ├── postgres/
│   ├── hadoop/
│   └── spark/
├── wordpress-k8s/
├── ingress/
└── namespaces/
```

## Deliverables

- PySpark notebook (.ipynb) with full ETL pipeline
- Docker Compose stack (production-ready)
- Kubernetes manifests (namespace isolation, RBAC, HPA, NetworkPolicy)
- Power BI report (.pbix) with Top 10 products + regional heatmap
- YARN UI screenshot showing successful Spark jobs
- HDFS UI screenshot showing raw data storage

## Author

r1bit99 — Big Data Engineering Project
Tek-Up University, 2026
```

That's your README. 🎯
