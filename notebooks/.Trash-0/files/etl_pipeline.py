from pyspark.sql import SparkSession, functions as F

spark = SparkSession.builder \
    .appName("ETL-WordPress-to-HDFS") \
    .master("local[*]") \
    .config("spark.sql.catalogImplementation", "hive") \
    .enableHiveSupport() \
    .getOrCreate()

# 1. Extract from WordPress PostgreSQL
df = spark.read.format("jdbc") \
    .option("url", "jdbc:postgresql://postgres:5432/wordpress") \
    .option("dbtable", "sales_data") \
    .option("user", "hiveuser") \
    .option("password", "hivepassword") \
    .option("driver", "org.postgresql.Driver") \
    .load()

print(f"Extracted {df.count()} records from WordPress")
df.show()

# 2. Clean
df = df.dropDuplicates().dropna(subset=["product", "region"])

# 3. Transform
df = df.withColumn("chiffre_affaires", F.col("quantity") * F.col("price"))

# 4. Load to HDFS
df.write.mode("overwrite").csv("hdfs://namenode:9000/data/wordpress_sales/raw", header=True)
print("Saved to HDFS!")

# 5. Save to Hive Metastore
df.write.mode("overwrite").saveAsTable("wordpress_sales")
print("Saved to Metastore!")

spark.sql("SELECT * FROM wordpress_sales").show()