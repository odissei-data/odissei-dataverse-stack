#!/bin/bash

# Upgrade The Odissei portal, from 6.4 to 6.5
# https://github.com/IQSS/dataverse/releases/tag/v6.5

echo "--- Upgrading Dataverse from 6.4 to 6.5 ---"

UPGRADE_DIR="utils/upgrades/6.4to6.5"
# get the absolute path to this UPGRADE_DIR
ABS_UPGRADE_DIR="$(cd "$(dirname "$UPGRADE_DIR")" && pwd)/$(basename "$UPGRADE_DIR")"
echo "Using upgrade directory: $ABS_UPGRADE_DIR"
SQL_DUMP_FILENAME="upgrade-from6.4-dump.sql"
DOT_ENV_FILENAME="dot_env_6.5"

# make sure we are running from the project root
# check that we have a file (this one) at utils/upgrades/6.4to6.5/upgrade.sh
if [ ! -f "$UPGRADE_DIR/upgrade.sh" ]; then
    echo "Make sure you are in the top directory of the project!"
    exit 1
fi

# Load environment variables.
set -a
source .env
set +a


### Helper functions

# Function to check if the bootstrap container is still running
is_running() {
  status=$(docker inspect --format='{{.State.Status}}' "$BOOTSTRAP_CONTAINER")
  if [ "$status" = "exited" ]; then
    return 1
  else
    return 0
  fi
}


### Main script starts here

# Stop only the dataverse container, just to prevent db mutations
echo "--- Stop Dataverse..."
docker stop "$DATAVERSE_CONTAINER"

# NOTE I would like to use the DATAVERSE_DB_USER, should I source that other .env file?

# Store a Postgres dump
# In some upgrades "pg_dump --clean -U dataverse dataverse" might be enough, 
# but pg_dumpall will always work
echo "--- Dump Postgres database..."
docker exec -i "$POSTGRES_CONTAINER" /bin/bash -c "pg_dumpall --clean -U dataverse" > "$UPGRADE_DIR/$SQL_DUMP_FILENAME"

# Down the dataverse container (no -v, we wipe the mounted volumes later on)
echo "--- Downing the datverse container..."
docker compose -f dataverse/docker-compose.yml down -v

# should wipe volumes, because we have a new dataverse, postgres and a new solr
#docker volume rm dev_dataverse dev_postgres dev_solr
echo "--- Wiping docker volumes..."
sudo rm -rf ./dataverse/docker-dev-volumes


# replace the .env with the new one specific for this upgrade
echo "--- Replacing the .env file..."
cp "$UPGRADE_DIR/$DOT_ENV_FILENAME" dataverse/.env

# Deploy the new containers
echo "--- Deploying the new containers..."

# Upping the Dataverse stack.
docker compose -f dataverse/docker-compose.yml up -d

# Wait for the bootstrap container to finish
echo "Waiting for the bootstrap container to finish..."
while is_running; do
  sleep 5
  echo "Still waiting..."
done

echo "Bootstrapping dataverse has finished!"

# stop only the dev_dataverse container, just to prevent mutations
echo "--- Stop Dataverse..."
docker stop "$DATAVERSE_CONTAINER"
# restore the Postgres dump
echo "--- Restoring Postgres database..."
#docker exec -i dev_postgres /bin/bash -c "psql -U dataverse dataverse" < utils/upgrades/6.4to6.5/upgrade-from6.4-dump.sql
docker exec -i "$POSTGRES_CONTAINER" /bin/bash -c "psql -X -U dataverse postgres" < "$UPGRADE_DIR/$SQL_DUMP_FILENAME"
# Start the dev_dataverse container
echo "--- Starting the dev_dataverse container..."
docker start "$DATAVERSE_CONTAINER"

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
# so maybe we could have kept that dataverse/docker-dev-volumes/app/ dir
echo "--- Configuring web analytics..."
sh utils/dataverse/configure_web_analytics.sh "$DATAVERSE_CONTAINER" "$DATAVERSE_WEB_ANALYTICS_ID"
echo "--- Web analytics configured!"

# Copy dataset.xhtml with file and version tab removed to volume.
echo "--- Copying dataset.xhtml with file and version tab removed..."
utils/dataverse/mounts/update.sh "$DATAVERSE_CONTAINER"
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

### Fix Search indexing
echo "--- Fixing Search indexing ---"

# Import SOLR schema 
# supplied with the release of the deployed Dataverse version!
# and update the schema with the custom metadata blocks
echo "--- Importing SOLR schema and config..."
sh utils/solr/schema-update/update.sh "$DATAVERSE_CONTAINER" "$SOLR_CONTAINER" "$ABS_UPGRADE_DIR/schema.xml"
echo ""
# This will be indexing...
echo "--- SOLR schema and config imported, reindexing is ongoing..."

# NOTE the schema-update needs to do a clear and full re-indexing, which is default now!

# NOT sure why, but lets wait some extra time here
echo "--- Waiting 30 seconds, just to be sure..."
sleep 30


# Print the version of Dataverse
echo "Dataverse version:"
docker exec "$DATAVERSE_CONTAINER" curl -s http://localhost:8080/api/info/version    
echo ""
echo "Upgrade from 6.4 to 6.5 completed successfully!"
