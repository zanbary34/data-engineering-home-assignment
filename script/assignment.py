from pyspark.sql import SparkSession
from pyspark.sql.functions import col, lag, avg, stddev, sum as _sum, count
from pyspark.sql.window import Window

# Initialize Spark Session
spark = SparkSession.builder.appName("DataEngineeringAssignment").getOrCreate()

# S3 Bucket Name
s3_bucket_name = "sefi-data-engineer-assignment"

# Input and Output Paths
input_path = f"s3://{s3_bucket_name}/input/stocks_data.csv"
output_avg_return_path = f"s3://{s3_bucket_name}/output/average_daily_return/"
output_highest_worth_path = f"s3://{s3_bucket_name}/output/highest_worth/"
output_most_volatile_path = f"s3://{s3_bucket_name}/output/most_volatile/"
output_top_30_day_returns_path = f"s3://{s3_bucket_name}/output/top_30_day_returns/"

# Load Dataset
df = spark.read.csv(input_path, header=True, inferSchema=True)

# Ensure proper data types
df = df.withColumn("close", col("close").cast("double")) \
       .withColumn("volume", col("volume").cast("double"))

# Add daily return column
window_spec = Window.partitionBy("ticker").orderBy("date")
df = df.withColumn("prev_close", lag("close").over(window_spec))
df = df.withColumn("daily_return", (col("close") - col("prev_close")) / col("prev_close"))

# Objective 2: Stock with Highest Worth (Only the Top Ticker and Avg Worth)
df = df.withColumn("worth", col("close") * col("volume"))
highest_worth = df.groupBy("ticker").agg(
    _sum("worth").alias("total_worth"),
    count("date").alias("days")
).withColumn("avg_worth", col("total_worth") / col("days"))
highest_worth = highest_worth.select("ticker", "avg_worth").orderBy(col("avg_worth").desc()).limit(1)
highest_worth = highest_worth.withColumn("avg_worth", col("avg_worth").cast("decimal(20,3)"))
highest_worth.write.parquet(output_highest_worth_path, mode="overwrite")

# Objective 3: Most Volatile Stock (Ticker and Standard Deviation)
volatility = df.groupBy("ticker").agg(stddev("daily_return").alias("standard_deviation"))
most_volatile = volatility.select("ticker", "standard_deviation").orderBy(col("standard_deviation").desc()).limit(1)
most_volatile.write.parquet(output_most_volatile_path, mode="overwrite")

# Objective 4: Top Three 30-Day Return Dates (Ticker and Date)
window_spec = Window.partitionBy("ticker").orderBy("date")
df = df.withColumn("price_30_days_ago", lag("close", 30).over(window_spec))
df = df.withColumn("return_30_days", (col("close") - col("price_30_days_ago")) / col("price_30_days_ago"))
top_30_day_returns = df.orderBy(col("return_30_days").desc()).select("ticker", "date").limit(3)
top_30_day_returns.write.parquet(output_top_30_day_returns_path, mode="overwrite")

# Stop Spark Session
spark.stop()

