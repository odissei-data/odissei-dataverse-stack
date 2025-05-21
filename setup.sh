#!/bin/bash
#
# This script contains a number of setup actions which help prepare the dataverse and Skosmos environments.

# Load environment variables.
set -a
source .env
set +a
echo "Bootstrap container: $BOOTSTRAP_CONTAINER"
# Initiating the submodule and fetching any changes.
git submodule init && git submodule update --remote

# Switching out the .ttl config and docker-compose for our setup.
cp utils/skosmos/docker-compose-skosmos.ttl Skosmos/dockerfiles/config/config-docker-compose.ttl
cp utils/skosmos/docker-compose.yml Skosmos/docker-compose.yml

# Adding the docker-compose to the dataverse submodule
cp utils/dataverse/docker-compose.yml dataverse/docker-compose.yml
cp utils/dataverse/dot_env dataverse/.env

# Create Traefik network
docker network create traefik

# Upping the Skosmos and Dataverse stacks.
docker compose -f Skosmos/docker-compose.yml up -d
docker compose -f dataverse/docker-compose.yml up -d

# Setup traefik container
docker compose -f utils/traefik/docker-compose.yml up -d

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

# Loading our metadata blocks.
echo "--- Loading metadata blocks..."
CUSTOM_METADATA_DIR="utils/Custom-Metadata-Blocks/tsv_files/"
cp utils/metadata/* "$CUSTOM_METADATA_DIR"
sh $CUSTOM_METADATA_DIR/upload.sh "$DATAVERSE_CONTAINER"
echo "--- Metadata blocks loaded!"

# Setup subverses and import licenses
echo "--- Setting up subverses and importing licenses..."
sh utils/dataverse/run_py_scripts.sh "$POSTGRES_CONTAINER"
echo "--- Subverses and licenses setup complete!"

# Setup dutch translation
echo "--- Setting up dutch translation..."
sh utils/language_setup.sh "$DATAVERSE_CONTAINER"
echo "--- Dutch translation setup complete!"

# Copy adjusted robots.txt
echo "--- Copying adjusted robots.txt..."
sh utils/dataverse/fix_robots_txt.sh "$DATAVERSE_CONTAINER"
echo "--- Adjusted robots.txt copied!"

# Configure web analytics
echo "--- Configuring web analytics..."
sh utils/dataverse/configure_web_analytics.sh "$DATAVERSE_CONTAINER" "$DATAVERSE_WEB_ANALYTICS_ID"
echo "--- Web analytics configured!"

# Configure NavbarGuidesUrl
echo "--- Configuring NavbarGuidesUrl..."
docker exec "$DATAVERSE_CONTAINER" curl -X PUT -d "$DATAVERSE_NAVBAR_GUIDES_URL" http://localhost:8080/api/admin/settings/:NavbarGuidesUrl
echo "--- NavbarGuidesUrl configured!"

# Import SOLR schema and config
echo "--- Importing SOLR schema and config..."
sh utils/solr/copy_solr.sh "$SOLR_CONTAINER"
echo "--- SOLR schema and config imported!"

# Note that teh schema is changed by the following action
# Update the schema.xml file with the new fields
echo "--- Updating schema.xml file with new fields..."
sh utils/solr/schema/update.sh "$DATAVERSE_CONTAINER" "$SOLR_CONTAINER" 
echo "--- Schema.xml file updated!"


# Turn of sign up options
echo "--- Turning off sign up options..."
docker exec "$DATAVERSE_CONTAINER" curl -X PUT -d 'false' http://localhost:8080/api/admin/settings/:AllowSignUp
echo "--- Sign up options turned off!"

# Copy dataset.xhtml with file and version tab removed to volume.
echo "--- Copying dataset.xhtml with file and version tab removed..."
# test if we have the file in a target dir, assuming that is a Dataverse development setup
if [ -f dataverse/target/dataverse/dataset.xhtml ]; then
  echo "dataset.xhtml exists in target dir, copying assuming Dataverse development setup..."
else
  echo "dataset.xhtml does not exist in target dir, copying to dataverse container..."
  docker cp utils/dataverse/mounts/dataset.xhtml "$DATAVERSE_CONTAINER:/opt/payara/deployments/dataverse/dataset.xhtml"
fi
echo "--- dataset.xhtml copied!"

echo "Restarting dataverse container..."
# Restart the dataverse container to pick up the new dataset.xhtml
docker restart "$DATAVERSE_CONTAINER"

echo "--- Setup complete!"
echo "Please wait for Dataverse to start up, this can take a while depending on your machine."
# could check if the container is running...
#echo "You can now access the dataverse at http://localhost:8080 and Skosmos at http://localhost:8081"