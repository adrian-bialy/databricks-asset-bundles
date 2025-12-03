# Databricks Asset Bundles – Demo

This repository is a self‑service demo that shows how to use **Databricks Asset Bundles** to develop, validate, deploy, and run Databricks workloads on Azure.

Official Documentation: https://learn.microsoft.com/en-us/azure/databricks/dev-tools/bundles/

You will:

- Create Azure + Databricks resources with a single script  
- Initialize a Databricks Asset Bundle from a template  
- Develop and test a Python project locally  
- Deploy & run jobs via Databricks Asset Bundles  
- Wire everything into GitHub Actions CI/CD

---

## Prerequisites

- An **Azure subscription** with permissions to:
  - Create resource groups
  - Deploy Bicep templates
  - Create Databricks workspaces
- **Recommended**: run this in a **Dev Container** or **GitHub Codespace** (already configured in [`.devcontainer/devcontainer.json`](.devcontainer/devcontainer.json)).

---

## 1. Fork and clone the repository

1. Fork this repo into your own GitHub account.  
2. Clone your fork locally or open it directly in a GitHub Codespace / Dev Container.

---

## 2. Create Azure and Databricks resources

The script [`azure/deploy.sh`](azure/deploy.sh) deploys the Bicep template [`azure/main.bicep`](azure/main.bicep) and configures Databricks.

From the repo root, run:

```bash
chmod +x azure/deploy.sh
./azure/deploy.sh
```

### **The script will:**

1. **Log in to Azure**  
   - Follow the instructions in your terminal and browser (Authentication is handled via the Azure CLI device code flow).

2. **Create / update resources** in your subscription:
   - **Resource Group**: `${PREFIX}-rg`
   - **Azure Key Vault**: `${PREFIX}-kv`
   - **Databricks Workspace** (trial SKU): `${PREFIX}-dbx`
   - Assign **Key Vault Secrets Officer** role for your user on the Key Vault.

3. **Configure Databricks**:
   - Install / update the `databricks` Azure CLI extension if needed.
   - Discover the Databricks workspace URL and set `$DATABRICKS_HOST`.
   - Prompt you to **authenticate with Databricks** using the Databricks CLI.
   - Create a small **shared cluster**.
   - Create a long‑lived **Personal Access Token (PAT)**.

4. **Store secrets in Azure Key Vault**:
   - `databricks-host`
   - `databricks-cluster-id`
   - `databricks-warehouse-id`
   - `databricks-token`
   
   These will be reused later.

> If deployment fails, check the Azure Portal for the resource group named `${PREFIX}-rg` and the deployment logs, then rerun `./azure/deploy.sh` after fixing the issue.

---

## 3. Enable Serverless (optional but recommended)

In the Databricks account console:

1. Go to: <https://accounts.azuredatabricks.net>  
2. As an admin, **enable Serverless** for your workspace (if available in your region / SKU).

This is needed if you want to use serverless SQL warehouses or compute in the demo.

---

## 4. Initialize a Databricks Asset Bundle

From the project root:

```bash
databricks bundle init https://github.com/adrian-bialy/databricks-asset-bundle-template
```

Notes:

- You can also use an official template like default-python, but for this demo we use the custom template above.
- The init command will ask:
  - Unique name for this project (e.g., demo)
  - Include a job that runs a notebook (yes/no)
  - Include an ETL pipeline (yes/no)
  - Include a sample Python package that builds into a wheel file (yes/no)
  - Use serverless compute (yes/no)
  - Default catalog for tables (press Enter to accept the shown default or provide one)
  - Use a personal schema for each user (yes/no; recommended)

**Recommendation**: answer Yes to all except the catalog, where you can press Enter to accept the default.

Remember the values you choose; they are needed in the next steps.

---

## 5. Install Python dependencies

This project uses **Poetry** for dependency management. Run:

```bash
poetry install --with dev
```

This installs the main and development dependencies inside the container.

---

## 6. Test the Python module locally

You can run your main Python module directly using Poetry. Replace placeholders with the values you configured during bundle init:

You can provide `DATABRICKS_SERVERLESS_COMPUTE_ID="auto"` for Serverless and `DATABRICKS_CLUSTER_ID="{cluster_id}"` for Clusters
```bash
export DATABRICKS_SERVERLESS_COMPUTE_ID="auto"

poetry run python -m {project_name}.main \
  --catalog {catalog_name} \
  --schema {schema_name}
```

- `{project_name}` – the Python package / project name used in the template.
- `{catalog_name}` / `{schema_name}` – must already exist or be creatable in your workspace.

This step validates that your core logic works locally before involving Databricks jobs or pipelines.

---

## 7. Select python interpreter to poetry's
1. Open VSC commands: `CTRL + SHIFT + P`
2. Select `Python: Select Interpreter`
3. Select poetry's environment `{project_name}-...`

---

## 8. Test debugger
1. Add some breakpoint in the code `./src/{project_name}/main.py`
2. Open Run and Debug: `CTRL + SHIFT + D`
3. Run `Example Debug` to break the execution and check variables.

Note: This is an example to show how easy is to debug the source code running on cluster.

---

## 9. Validate your Databricks Asset Bundle

Use the **Databricks Asset Bundles** CLI to validate the configuration. You will pass cluster and warehouse IDs as variables.

First, retrieve IDs from Key Vault (if you didn’t note them earlier):
- databricks_cluster_id
- databricks_warehouse_id


Then run:

```bash
databricks bundle validate -t dev \
  --var cluster_id={cluster_id} \
  --var warehouse_id={warehouse_id}
```

If validation fails, fix the reported issues in your bundle config (e.g., `bundle.yml`, job definitions, paths).

---

## 10. Deploy the bundle

Once validation succeeds, deploy the bundle to the `dev` target:

```bash
databricks bundle deploy -t dev \
  --var cluster_id={cluster_id} \
  --var warehouse_id={warehouse_id}
```

This will:

- Upload code and dependencies to Databricks
- Create / update jobs, workflows, pipelines, and other resources defined in the bundle

---

## 11. Run a job from the bundle

To execute a deployed job:

```bash
databricks bundle run sample_job -t dev \
  --var cluster_id={cluster_id} \
  --var warehouse_id={warehouse_id}
```

- `{job_name}` is the name of the job defined in the bundle (e.g. in `bundle.yml` or job config files).
- You can monitor runs in the Databricks workspace UI.

---

## 12. Configure GitHub Actions (optional CI/CD)

To enable CI/CD from GitHub, add the following as **GitHub Actions secrets / variables** (values are in the Key Vault created by `deploy.sh`):

- `DATABRICKS_HOST` – from Key Vault secret `databricks-host`
- `DATABRICKS_TOKEN` – from Key Vault secret `databricks-token`
- `DATABRICKS_CLUSTER_ID` – from Key Vault secret `databricks-cluster-id`
- `DATABRICKS_WAREHOUSE_ID` – from Key Vault secret `databricks-warehouse-id`

Then:

1. Commit your changes and push to your fork’s `main` (or chosen) feature branch.
2. Inspect GitHub Actions runs in the **Actions** tab for:
   - Tests
   - Deployment to Databricks

---

## 13. Explore the deployed assets

Once everything is deployed, explore the objects created in your Databricks workspace:

- Jobs and job runs
- Workflows and pipelines
- Delta tables, catalogs, schemas
- Dashboards

This is where you can experiment with modifying the bundle and observing how CI/CD and deployments behave.

---

## Cleanup

To avoid incurring ongoing costs, delete the resource group when you’re done:

```bash
az group delete --name "${PREFIX}-rg" --yes --no-wait
```

This removes the Databricks workspace, Key Vault, and related resources created by this demo.

---

## Support / Issues

If you encounter problems:

- Check the logs of `./azure/deploy.sh`
- Review Azure deployment logs in the Portal
- Run `databricks bundle validate` again after config changes
- Open an issue in your fork or in the upstream repository with:
  - Error messages
  - Steps to reproduce
  - Environment details (Dev Container / Codespace / local)