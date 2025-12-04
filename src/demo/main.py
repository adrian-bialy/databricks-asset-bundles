import argparse
from demo.spark import (
    build_spark_session,
    configure_spark,
)
from demo import taxis


def main():
    # Process command-line arguments
    parser = argparse.ArgumentParser(description="Databricks job with catalog and schema parameters")
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    args = parser.parse_args()

    spark = build_spark_session()
    spark = configure_spark(spark)

    # Set the default catalog and schema
    spark.sql(f"USE CATALOG {args.catalog}")
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {args.schema}")
    spark.sql(f"USE SCHEMA {args.schema}")

    # Example: just find all taxis from a sample catalog
    df = taxis.find_all_taxis()
    df_count = df.count()
    taxis.find_all_taxis().show(5)


if __name__ == "__main__":
    main()