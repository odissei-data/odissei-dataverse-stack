#!/bin/bash

# Upgrade The Odissei portal, from 6.4 to 6.6
# https://github.com/IQSS/dataverse/releases/tag/v6.6

echo "--- Upgrading Dataverse from 6.4 to 6.6 ---"

UPGRADE_DIR="utils/upgrades/6.4to6.6"
# get the absolute path to this UPGRADE_DIR
ABS_UPGRADE_DIR="$(cd "$(dirname "$UPGRADE_DIR")" && pwd)/$(basename "$UPGRADE_DIR")"
echo "Using upgrade directory: $ABS_UPGRADE_DIR"

# make sure we are running from the project root
#cd "$(dirname "$0")/../../" || exit 1

# check that we have a file (this one) at this upgrade directory
if [ ! -f "$UPGRADE_DIR/upgrade.sh" ]; then
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
#docker exec -i dev_postgres /bin/bash -c "pg_dump --clean -U dataverse dataverse" > "$UPGRADE_DIR/upgrade-from6.4-dump.sql"
docker exec -i "$POSTGRES_CONTAINER" /bin/bash -c "pg_dumpall --clean -U dataverse" > "$UPGRADE_DIR/upgrade-from6.4-dump.sql"

# Down the dataverse container
echo "--- Downing the datverse container..."
docker compose -f dataverse/docker-compose.yml down -v

# should wipe volumes, because we have a new dataverse, postgres and a new solr
#docker volume rm dev_dataverse dev_postgres dev_solr
echo "--- Wiping docker dev volumes..."
sudo rm -rf ./dataverse/docker-dev-volumes


# replace the .env with the new one specific for this upgrade
echo "--- Replacing the .env file..."
cp "$UPGRADE_DIR/dot_env_6.6" dataverse/.env

# Deploy the new containers
echo "--- Deploying the new containers..."

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

# stop only the dev_dataverse container, just to prevent mutations
echo "--- Stop Dataverse..."
docker stop dev_dataverse
# restore the Postgres dump
echo "--- Restoring Postgres database..."
#docker exec -i dev_postgres /bin/bash -c "psql -U dataverse dataverse" < "$UPGRADE_DIR/upgrade-from6.4-dump.sql"
docker exec -i "$POSTGRES_CONTAINER" /bin/bash -c "psql -X -U dataverse postgres" < "$UPGRADE_DIR/upgrade-from6.4-dump.sql"

# Start the dev_dataverse container
echo "--- Starting the dev_dataverse container..."
docker start dev_dataverse


# wait for Dataverse to be up
echo "Waiting for Dataverse to be up..."
while ! docker exec "$DATAVERSE_CONTAINER" curl -s http://localhost:8080/api/info/version > /dev/null; do
    sleep 5
    echo "Still waiting..."
done
echo "Dataverse is up."

echo "--- Waiting 30 seconds, just to be sure..."
sleep 30


### Repair the dataverse container ODISEI changes
echo "--- Repairing the dataverse container with ODISSEI changes ---"

# Setup dutch translation
echo "--- Setting up dutch translation..."
sh utils/language_setup.sh "$DATAVERSE_CONTAINER"
echo "--- Dutch translation setup complete!"

# Copy adjusted robots.txt
echo "--- Copying adjusted robots.txt..."
sh utils/dataverse/fix_robots_txt.sh "$DATAVERSE_CONTAINER"
echo "--- Adjusted robots.txt copied!"

# Configure web analytics
# The file needed was in dataverse/docker-dev-volumes/app/data/branding/web-analytics.html
# sow we could have kept that dataverse/docker-dev-volumes/app/ dir
echo "--- Configuring web analytics..."
sh utils/dataverse/configure_web_analytics.sh "$DATAVERSE_CONTAINER" "$DATAVERSE_WEB_ANALYTICS_ID"
echo "--- Web analytics configured!"

# Copy dataset.xhtml with file and version tab removed to volume.
echo "--- Copying dataset.xhtml with file and version tab removed..."
sh utils/dataverse/mounts/update.sh "$DATAVERSE_CONTAINER"
echo "--- dataset.xhtml copied!"

echo "--- Restarting dataverse container..."
# Restart the dataverse container to pick up the new dataset.xhtml
docker restart "$DATAVERSE_CONTAINER"

# NOT sure why Solr import fails if we don't, but lets wait some extra time here
echo "--- Waiting 30 seconds, just to be sure..."
sleep 30

# wait for Dataverse to be up
echo "Waiting for Dataverse to be up..."
while ! docker exec "$DATAVERSE_CONTAINER" curl -s http://localhost:8080/api/info/version > /dev/null; do
    sleep 5
    echo "Still waiting..."
done
echo "Dataverse is up."

### Update the Metadata blocks
echo "--- Updating metadata blocks ---"
docker cp "$UPGRADE_DIR/tsv_files" "$DATAVERSE_CONTAINER":/opt/payara/tsv_files
docker exec "$DATAVERSE_CONTAINER" curl http://localhost:8080/api/admin/datasetfield/load -H "Content-type: text/tab-separated-values" -X POST --upload-file /opt/payara/tsv_files/citation.tsv
docker exec "$DATAVERSE_CONTAINER" curl http://localhost:8080/api/admin/datasetfield/load -H "Content-type: text/tab-separated-values" -X POST --upload-file /opt/payara/tsv_files/3d_objects.tsv


### Fix Search indexing
echo "--- Fixing Search indexing ---"

# Import SOLR schema 
# supplied with the release of the deployed Dataverse version!
# and update the schema with the custom metdata blocks
echo "--- Importing SOLR schema and config..."
sh utils/solr/schema-update/update.sh "$DATAVERSE_CONTAINER" "$SOLR_CONTAINER" "$ABS_UPGRADE_DIR/schema.xml"
echo ""
# This will be indexing...
echo "--- SOLR schema and config imported, reindexing..."

# NOT sure why, but lets wait some extra time here
echo "--- Waiting 30 seconds, just to be sure..."
sleep 30


## We must do full reindexing, with a clear. 
## It has to do with the imported database, those timestamps have to be removed otherwise it's not reindexing
echo "--- Clearing and reindexing the Solr index..."
docker exec "$DATAVERSE_CONTAINER" curl http://localhost:8080/api/admin/index/clear
docker exec "$DATAVERSE_CONTAINER" curl http://localhost:8080/api/admin/index
echo ""
echo "--- Reindexing started and will be ongoing..."


# Print the version of Dataverse
echo "Dataverse version:"
docker exec "$DATAVERSE_CONTAINER" curl -s http://localhost:8080/api/info/version    
echo ""
echo "Upgrade from 6.4 to 6.6 completed successfully!"
