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

# Adding the docker-compose to the dataverse submodule
cp dataverse/dot_env dataverse/.env

# Create Traefik network
docker network create traefik

# Upping the Dataverse stack.
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

# Solr should be ok for Dataverse already
# However, this seems NOT to be the case!
# Import SOLR schema and config, 
# supplied with the release of the deployed Dataverse version!
echo "--- Importing SOLR schema and config..."
sh utils/solr/copy_solr.sh "$SOLR_CONTAINER"
echo "--- SOLR schema and config imported!"

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

# Configure Notifications
echo "--- Configuring Notifications..."
# Enable to show options in UI
docker exec "$DATAVERSE_CONTAINER" curl -X PUT -d 'true' http://localhost:8080/api/admin/settings/:ShowMuteOptions
# Mute all that have to do with Dataset import, create and publish
docker exec "$DATAVERSE_CONTAINER" curl -X PUT -d 'CREATEDS,CREATEDV,DATASETCREATED,FILESYSTEMIMPORT,PUBLISHEDDS,PUBLISHFAILED_PIDREG,STATUSUPDATED,SUBMITTEDDS,WORKFLOW_FAILURE,WORKFLOW_SUCCESS,SUBMITTEDDS,WORKFLOW_FAILURE,WORKFLOW_SUCCESS' http://localhost:8080/api/admin/settings/:AlwaysMuted
echo "--- Notifications configured!"

# Note that the schema is changed by the following action
# Update the schema.xml file with our custom fields
echo "--- Updating schema.xml file with new fields..."
sh utils/solr/schema-update/update.sh "$DATAVERSE_CONTAINER" "$SOLR_CONTAINER" 
echo "--- Schema.xml file updated!"

# Turn of sign up options
echo "--- Turning off sign up options..."
docker exec "$DATAVERSE_CONTAINER" curl -X PUT -d 'false' http://localhost:8080/api/admin/settings/:AllowSignUp
echo "--- Sign up options turned off!"

# Setup cvocconf
echo "--- Setting up cvocconf..."
docker cp utils/external_vocabularies/cvocconf.json "$DATAVERSE_CONTAINER":/opt/payara/cvocconf.json
docker exec "$DATAVERSE_CONTAINER" curl -X PUT --upload-file cvocconf.json http://localhost:8080/api/admin/settings/:CVocConf
docker exec "$DATAVERSE_CONTAINER" mkdir /opt/payara/deployments/dataverse/custom
docker cp utils/external_vocabularies/skosmos.js "$DATAVERSE_CONTAINER":/opt/payara/deployments/dataverse/custom/skosmos.js
echo "--- cvocconf setup complete!"

# Copy dataset.xhtml with file and version tab removed to volume.
echo "--- Copying dataset.xhtml with file and version tab removed..."
# test if we have the file in a target dir, assuming that is a Dataverse development setup
if [ -f dataverse/target/dataverse/dataset.xhtml ]; then
  echo "dataset.xhtml exists in target dir, NOT copying assuming Dataverse development setup..."
else
  echo "dataset.xhtml does not exist in target dir, copying to dataverse container..."
  #docker cp utils/dataverse/mounts/dataset.xhtml "$DATAVERSE_CONTAINER:/opt/payara/deployments/dataverse/dataset.xhtml"
  utils/dataverse/mounts/update.sh "$DATAVERSE_CONTAINER"
fi
echo "--- dataset.xhtml copied!"

echo "Restarting dataverse container..."
# Restart the dataverse container to pick up the new dataset.xhtml
docker restart "$DATAVERSE_CONTAINER"

echo "--- Setup complete!"
echo "Please wait for Dataverse to start up, this can take a while depending on your machine."
# could check if the container is running...
#echo "You can now access the dataverse at http://localhost:8080 and Skosmos at http://localhost:8081"