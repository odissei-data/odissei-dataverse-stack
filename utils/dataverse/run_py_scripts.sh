#!/bin/bash

postgres_container=$1

echo "--- Retrieving API token..."
api_token=$(docker exec -i "$postgres_container" psql -U dataverse -d dataverse -t -c "SELECT tokenstring FROM apiToken WHERE authenticateduser_id = 1" | tr -d '[:space:]')

echo "--- Got API token: $api_token"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CURRENT_DIR="$(pwd)"

cd "$SCRIPT_DIR" || exit 1

echo "--- Running Python scripts with Poetry..."
poetry install
poetry run python create_dataverses.py "$ROOT_URL" "$api_token"
poetry run python import-licenses.py "$ROOT_URL" "$api_token"
echo "--- Python scripts completed!"

cd "$CURRENT_DIR" || exit 1
