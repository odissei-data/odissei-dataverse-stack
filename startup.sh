#!/bin/bash

echo "Starting up the ODISSEI portal containers..."
echo "Assuming the setup was run once before!"

# Load environment variables.
set -a
source .env
set +a


# Create Traefik network, only when it does not exists
if ! docker network inspect traefik >/dev/null 2>&1; then
  echo "Creating Traefik network..."
  docker network create traefik
else
  echo "Traefik network already exists, skipping creation."
fi

# Upping the Dataverse stack.
docker compose -f dataverse/docker-compose.yml up -d

# Setup traefik container
docker compose -f utils/traefik/docker-compose.yml up -d

wait_for_dataverse_up() {
  while true; do
    STATUS_CODE=$(docker exec "$DATAVERSE_CONTAINER" curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/info/version)
    
    if [ "$STATUS_CODE" -eq 200 ]; then
      echo "Dataverse is up."
      break
    else
      echo "Still waiting... (HTTP $STATUS_CODE)"
      sleep 5
    fi
  done
}
# wait for Dataverse to be up
echo "Waiting for Dataverse to be up..."
wait_for_dataverse_up

echo "Dataverse is up and running!"

# Note that if the dataverse container was downed we need to fix the dataset.xhtml file
# But if it was stopped we do not, but we can copy it anyway
echo "Fixing the dataset.xhtml file in the dataverse container, if it was downed..."
docker cp utils/dataverse/mounts/dataset_commented.xhtml "dev_dataverse:/opt/payara/deployments/dataverse/dataset.xhtml"

echo "ODISSEI portal is ready!"
