#!/usr/bin/env bash

# Configuration
PREFIX="dabwk21"        # 3–11 lowercase letters/numbers
LOCATION="westeurope"
RESOURCE_GROUP="${PREFIX}-rg"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BICEP_FILE="${SCRIPT_DIR}/main.bicep"

if [[ ! "$PREFIX" =~ ^[a-z0-9]{3,11}$ ]]; then
    echo "Invalid PREFIX: must be 3–11 lowercase letters/numbers" >&2
    exit 1
fi

echo "Logging into Azure..."
az login --use-device-code >/dev/null

echo "Retrieving current user objectId..."
CURRENT_USER_OBJECT_ID="$(az ad signed-in-user show --query id -o tsv 2>/dev/null || true)"
if [[ -z "$CURRENT_USER_OBJECT_ID" ]]; then
    echo "Failed to get current user objectId" >&2
    exit 1
fi

echo "Creating resource group: $RESOURCE_GROUP ($LOCATION)"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" >/dev/null

echo "Deploying Bicep template..."
az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$BICEP_FILE" \
    --parameters prefix="$PREFIX" location="$LOCATION" currentUserObjectId="$CURRENT_USER_OBJECT_ID"

az extension add --name databricks --upgrade
export DATABRICKS_HOST="https://$(az databricks workspace show \
  --name "$PREFIX-dbx" \
  --resource-group "$RESOURCE_GROUP" \
  --query workspaceUrl -o tsv)"

echo "DATABRICKS_HOST is set to $DATABRICKS_HOST"

echo "Logging into Databricks..."
databricks auth login --host "$DATABRICKS_HOST" --profile DEFAULT

echo "Configuring Databricks..."
policy_id=$(databricks cluster-policies list --output json \
  | jq -r '.[] | select(.name=="Shared Compute").policy_id')

cluster_id=$(databricks clusters create --no-wait --json '{
  "cluster_name": "shared-cluster",
  "spark_version": "16.4.x-scala2.12",
  "node_type_id": "Standard_DS3_v2",
  "autotermination_minutes": 30,
  "policy_id": "'"$policy_id"'",
  "autoscale": {
      "min_workers": 1,
      "max_workers": 1
  }
}' | jq -r '.cluster_id')

export DATABRICKS_CLUSTER_ID="$cluster_id"

pat_json=$(databricks tokens create \
  --comment "PAT" \
  --lifetime-seconds 31536000)

pat=$(echo "$pat_json" | jq -r '.token_value')
export DATABRICKS_TOKEN="$pat"

az keyvault secret set --vault-name "$PREFIX-kv" \
  --name "databricks-host" --value "$DATABRICKS_HOST"

az keyvault secret set --vault-name "$PREFIX-kv" \
  --name "databricks-cluster-id" --value "$cluster_id"

az keyvault secret set --vault-name "$PREFIX-kv" \
  --name "databricks-token" --value "$pat"


echo "Deployment complete. Host: $DATABRICKS_HOST, Cluster ID: $DATABRICKS_CLUSTER_ID, Token set in Key Vault."