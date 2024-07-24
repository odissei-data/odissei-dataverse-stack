#!/bin/bash

postgres_container=$1

api_token=$(docker exec -i "$postgres_container" psql -U dataverse -d dataverse -t -c "SELECT tokenstring FROM apiToken WHERE authenticateduser_id = 1" | tr -d '[:space:]')

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CURRENT_DIR="$(pwd)"

cd "$SCRIPT_DIR" || exit 1

poetry install
poetry run python create_dataverses.py "$ROOT_URL" "$api_token"
poetry run python import-licenses.py "$ROOT_URL" "$api_token"

cd "$CURRENT_DIR" || exit 1
