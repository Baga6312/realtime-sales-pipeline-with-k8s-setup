FROM apache/spark:3.5.8

USER root

# Install Python dependencies
RUN apt-get update && apt-get install -y curl && \
    pip install jupyter notebook pyspark==3.5.8 pandas --no-cache-dir

# Download PostgreSQL JDBC driver
RUN curl -o /opt/spark/jars/postgresql-42.7.1.jar \
    https://jdbc.postgresql.org/download/postgresql-42.7.1.jar

# Copy start script
COPY start-spark.sh /start-spark.sh
RUN chmod +x /start-spark.sh

# Copy hive config
COPY hive-site.xml /opt/spark/conf/hive-site.xml

ENTRYPOINT ["/bin/bash", "/start-spark.sh"]