from demo.spark import build_spark_session
from pyspark.sql import DataFrame


def find_all_taxis() -> DataFrame:
    """Find all taxi data."""
    spark = build_spark_session()
    return spark.read.table("samples.nyctaxi.trips")