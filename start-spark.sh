#!/bin/bash

SPARK_HOME=/opt/spark

# Download PostgreSQL JDBC driver
echo "Downloading PostgreSQL JDBC driver..."
curl -o $SPARK_HOME/jars/postgresql-42.7.1.jar \
  https://jdbc.postgresql.org/download/postgresql-42.7.1.jar

# Install Jupyter + pyspark
pip install jupyter notebook pyspark==3.5.8

# Start Thrift Server in background
echo "Starting Thrift Server on port 10001..."
$SPARK_HOME/sbin/start-thriftserver.sh \
  --master local \
  --hiveconf hive.server2.transport.mode=http \
  --hiveconf hive.server2.thrift.http.port=10001 \
  --hiveconf hive.server2.thrift.http.path=cliservice \
  --hiveconf hive.server2.thrift.bind.host=0.0.0.0

sleep 5

# Start Jupyter
echo "Starting Jupyter on port 8888..."
python3 -m jupyter notebook \
  --ip=0.0.0.0 \
  --port=8888 \
  --no-browser \
  --allow-root \
  --notebook-dir=/notebooks \
  --NotebookApp.token='' \
  --NotebookApp.password=''