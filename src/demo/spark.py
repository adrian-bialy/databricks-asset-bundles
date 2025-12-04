from pyspark.sql import SparkSession


def configure_spark(
    spark: SparkSession,
) -> SparkSession:

    spark.conf.set(
        "spark.sql.session.timeZone",
        "UTC",
    )
    return spark


def build_spark_session() -> SparkSession:
    try:
        from databricks.connect import DatabricksSession

        session = DatabricksSession.builder.getOrCreate()
    except ImportError:
        session = SparkSession.builder.getOrCreate()
    return session
