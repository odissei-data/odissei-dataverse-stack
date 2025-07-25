#!/bin/bash

# Upgrade The Odissei portal, from 6.4 to 6.5
# https://github.com/IQSS/dataverse/releases/tag/v6.5

echo "--- Upgrading Dataverse from 6.4 to 6.5 ---"


# make sure we are running from the project root
#cd "$(dirname "$0")/../../" || exit 1

# check that we have a file (this one) at utils/upgrades/6.4to6.5/upgrade.sh
if [ ! -f utils/upgrades/6.4to6.5/upgrade.sh ]; then
    echo "Make sure you are in the top directory of the project!"
    exit 1
fi

# Load environment variables.
set -a
source .env
set +a

# stop only the dev_dataverse container, just to prevent mutations
#echo "--- Stop Dataverse..."
#docker stop dev_dataverse

# store a Postgres dump 
echo "--- Dump Postgres database..."
docker exec -i dev_postgres /bin/bash -c "pg_dump --clean -U dataverse dataverse" > utils/upgrades/6.4to6.5/upgrade-from6.4-dump.sql

# Down the containers (-v wipes the volumes, BUT IT DOESN't?)
echo "--- Downing the containers..."
docker compose -f dataverse/docker-compose.yml down -v

# should wipe volumes, because we have a new dataverse, postgres and a new solr
#docker volume rm dev_dataverse dev_postgres dev_solr
echo "--- Wiping docker dev volumes..."
sudo rm -rf ./dataverse/docker-dev-volumes


# replace the .env with the new one
echo "--- Replacing the .env file..."
cp utils/upgrades/6.4to6.5/dot_env_6.5 dataverse/.env

# Deploy the new containers
echo "--- Deploying the new containers..."

## NEED TO DO Traefik stuff here, copied from the setup script?
# Create Traefik network
#docker network create traefik

# Upping the Dataverse stack.
docker compose -f dataverse/docker-compose.yml up -d

# Setup traefik container
#docker compose -f utils/traefik/docker-compose.yml up -d


# Function to check if the bootstrap container is still running
is_running() {
  status=$(docker inspect --format='{{.State.Status}}' "$BOOTSTRAP_CONTAINER")
  if [ "$status" = "exited" ]; then
    return 1
  else
    return 0
  fi
}

# Wait for the bootstrap container to finish
echo "Waiting for the bootstrap container to finish..."
while is_running; do
  sleep 5
  echo "Still waiting..."
done

echo "Bootstrapping dataverse has finished!"

# wait for the dataverse to be up
# echo "Waiting for the containers to be up..."
# while ! docker exec dev_dataverse curl -s http://localhost:8080/api/info/version  > /dev/null; do
#     sleep 5
# done
# echo "Containers are up."

#####

####

### TEST SKIP THIS
# stop only the dev_dataverse container, just to prevent mutations
#echo "--- Stop Dataverse..."
#docker stop dev_dataverse
# restore the Postgres dump
echo "--- Restoring Postgres database..."
docker exec -i dev_postgres /bin/bash -c "psql -U dataverse dataverse" < utils/upgrades/6.4to6.5/upgrade-from6.4-dump.sql
#
# Start the dev_dataverse container
#echo "--- Starting the dev_dataverse container..."
#docker start dev_dataverse

# Copy dataset.xhtml with file and version tab removed to volume.
echo "--- Copying dataset.xhtml with file and version tab removed..."
sh utils/dataverse/mounts/update.sh "$DATAVERSE_CONTAINER"
echo "--- dataset.xhtml copied!"

echo "Restarting dataverse container..."
# Restart the dataverse container to pick up the new dataset.xhtml
docker restart "$DATAVERSE_CONTAINER"


# # restart the payara domain
# echo "--- Restarting the Payara domain..."
# docker exec -i "$DATAVERSE_CONTAINER" /bin/bash -c "/opt/payara/appserver/glassfish/bin/asadmin restart-domain domain1"

# NOT sure why, but lets wait some extra time here
echo "--- Waiting 30 seconds, just to be sure..."
sleep 30

# wait for Dataverse to be up
echo "Waiting for Dataverse to be up..."
while ! docker exec "$DATAVERSE_CONTAINER" curl -s http://localhost:8080/api/info/version > /dev/null; do
    sleep 5
    echo "Still waiting..."
done
echo "Dataverse is up."

# Import SOLR schema 
# supplied with the release of the deployed Dataverse version!
# and update the schema with the custom metdata blocks
echo "--- Importing SOLR schema and config..."
sh utils/solr/schema-update/update.sh "$DATAVERSE_CONTAINER" "$SOLR_CONTAINER" /home/paulb/git/odissei-devstack/utils/upgrades/6.4to6.5/schema.xml

# NOT sure why, but lets wait some extra time here
echo "--- Waiting 30 seconds, just to be sure..."
sleep 30


## Somehow we must do reindexing, with a clear, maybe we always do this in that schema-update script?
echo "--- Clearing and reindexing the Solr index..."
docker exec "$DATAVERSE_CONTAINER" curl http://localhost:8080/api/admin/index/clear
docker exec "$DATAVERSE_CONTAINER" curl http://localhost:8080/api/admin/index


# # restart the payara domain
# echo "--- Restarting the Payara domain..."
# docker exec -i "$DATAVERSE_CONTAINER" /bin/bash -c "/opt/payara/appserver/glassfish/bin/asadmin restart-domain domain1"

# # NOT sure why, but lets wait some extra time here
# echo "--- Waiting 30 seconds, just to be sure..."
# sleep 30

# wait for Dataverse to be up
echo "Waiting for Dataverse to be up..."
while ! docker exec "$DATAVERSE_CONTAINER" curl -s http://localhost:8080/api/info/version > /dev/null; do
    sleep 5
    echo "Still waiting..."
done
echo "Dataverse is up."


# Print the version of Dataverse
echo "Dataverse version:"
docker exec "$DATAVERSE_CONTAINER" curl -s http://localhost:8080/api/info/version    
echo "Upgrade from 6.4 to 6.5 completed successfully!"
