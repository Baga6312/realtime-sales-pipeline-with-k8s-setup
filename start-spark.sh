#!/bin/bash

# Download PostgreSQL JDBC driver if not present
if [ ! -f /opt/bitnami/spark/jars/postgresql-42.7.1.jar ]; then
  echo "Downloading PostgreSQL JDBC driver..."
  curl -o /opt/bitnami/spark/jars/postgresql-42.7.1.jar \
    https://jdbc.postgresql.org/download/postgresql-42.7.1.jar
fi

# Install Jupyter
pip install jupyter --quiet

# Start Thrift Server in background
echo "Starting Thrift Server on port 10001..."
/opt/bitnami/spark/sbin/start-thriftserver.sh \
  --master local \
  --hiveconf hive.server2.transport.mode=http \
  --hiveconf hive.server2.thrift.http.port=10001 \
  --hiveconf hive.server2.thrift.http.path=cliservice \
  --hiveconf hive.server2.thrift.bind.host=0.0.0.0

# Start Jupyter
echo "Starting Jupyter on port 8888..."
jupyter notebook \
  --ip=0.0.0.0 \
  --port=8888 \
  --no-browser \
  --allow-root \
  --notebook-dir=/notebooks \
  --NotebookApp.token='' \
  --NotebookApp.password=''
