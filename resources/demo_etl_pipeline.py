from databricks.bundles.pipelines import Pipeline

"""
The main pipeline for demo
"""

demo_etl = Pipeline.from_dict(
    {
        "name": "demo_etl",
        "catalog": "${var.catalog}",
        "schema": "${var.schema}",
        "serverless": True,
        "root_path": "src/demo_etl",
        "libraries": [
            {
                "glob": {
                    "include": "src/demo_etl/transformations/**",
                },
            },
        ],
        "environment": {
            "dependencies": [
                # We include every dependency defined by pyproject.toml by defining an editable environment
                # that points to the folder where pyproject.toml is deployed.
                "--editable ${workspace.file_path}",
            ],
        },
    }
)