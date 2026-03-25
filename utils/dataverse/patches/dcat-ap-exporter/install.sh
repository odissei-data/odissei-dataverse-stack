#!/bin/bash
#
# install the DCAT-AP exporter plugin
# downloaded from 
#  https://repo1.maven.org/maven2/io/gdcc/dcat-3/v0.8.3/dcat-3-v0.8.3.jar
#

set -e

# Get the dataverse container name from the parameter and, if not given, from the environment variable 
if [ -n "$1" ]; then
    DATAVERSE_CONTAINER="$1"
    echo "Using dataverse container from parameter: $DATAVERSE_CONTAINER"
elif [ -n "$DATAVERSE_CONTAINER" ]; then
    echo "Using dataverse container from environment variable: $DATAVERSE_CONTAINER"
else
    echo "No dataverse container specified as parameter or environment variable; exiting!"
    exit 1
fi

# Run this from the script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CURRENT_DIR="$(pwd)"
cd "$SCRIPT_DIR" || exit 1


# function to exit with message
exit_with_error_message() {
    local message="$1"
    echo "$message"
    # Get back to where we were
    cd "$CURRENT_DIR" || exit 1
    exit 1
}

# Assuming we have Datavesre setup with exporter plugins directory configured already

# we have the jar file here, so we can copy it
# Finally this will be done in the existing install_exporters.sh script


#JAR_FILE=./dcat-3-0.1.1-SNAPSHOT.jar
JAR_FILE=./dcat-3-v0.8.4.jar

### Almost copy paste the jar file copying from that other script

echo "Installing exporter jar files. Script directory: $SCRIPT_DIR"

# The dataverse docker volumes directory relative to this script
# this is different, extra two dirs up!
DOCKER_VOLUMES_DIR=../../../../dataverse/docker-dev-volumes

# Test if we have the docker volumes directory
if [ ! -d "$DOCKER_VOLUMES_DIR" ]; then
  exit_with_error_message "No $DOCKER_VOLUMES_DIR directory; exiting!"
fi

EXPORTER_DIR_SRC=.
EXPORTER_DIR_DST=$DOCKER_VOLUMES_DIR/app/data/exporters

# Create the destination directory if it doesn't exist
if [ ! -d "$EXPORTER_DIR_DST" ]; then
  echo "Creating exporter dir: $EXPORTER_DIR_DST"
  mkdir -p $EXPORTER_DIR_DST
fi

# NOTE maybe we have to rename the old jar file, 
# if it is accidentally used as an update instead of an install?
# But as long as it has the same filename it will overwrite it

# copy the specific jar file we want, and check if it exists
if [ -f "$JAR_FILE" ]; then
  echo "Copying $JAR_FILE to $EXPORTER_DIR_DST"
  cp "$JAR_FILE" "$EXPORTER_DIR_DST/"
else
  exit_with_error_message "No $JAR_FILE file found; exiting!"
fi

### Copy that config directory
# Note that both config and export dir are hardcoded in the docker-compose.yml
DCAT3_CONFIG_DIR=dcat3_config
CONFIG_DIR_DST=$EXPORTER_DIR_DST/$DCAT3_CONFIG_DIR

# Create the config destination directory if it doesn't exist
if [ ! -d "$CONFIG_DIR_DST" ]; then
  echo "Creating config dir: $CONFIG_DIR_DST"
  mkdir -p $CONFIG_DIR_DST
fi

CONFIG_DIR_SRC=./config
echo "Copying config properties files from $CONFIG_DIR_SRC to $CONFIG_DIR_DST"
cp $CONFIG_DIR_SRC/*.properties $CONFIG_DIR_DST/

# TODO
# set the JVM options for the exporter plugin: -Ddataverse.dcat3.config=/dv/exporters/$DCAT3_CONFIG_DIR/dcat-root.properties
# prevent duplicates: 
# DELETE it first, which can fail if it does not exist, but we can ignore that error
# when the value changes we need to delete the old one and the new one to be idempotent
#
# NOTE the following fails if not interactive; so it needs that -it
# and it must be entered twice, this is a hassle...
echo ""
echo "Setting JVM options for the exporter plugin to find the config files..."
echo "--- You need to provide asadmin credentials twice; sorry!"
echo ""
docker exec -it "$DATAVERSE_CONTAINER" asadmin delete-jvm-options "-Ddataverse.dcat3.config=/dv/exporters/${DCAT3_CONFIG_DIR}/dcat-root.properties" || true
docker exec -it "$DATAVERSE_CONTAINER" asadmin create-jvm-options "-Ddataverse.dcat3.config=/dv/exporters/${DCAT3_CONFIG_DIR}/dcat-root.properties"

# Restart the dataverse container to load the new exporter(s)
echo "Restarting dataverse container..."

# You must restart the dataverse container to load the new exporter(s).
echo "Restarting dataverse container to load the new exporter(s)..."
docker restart "$DATAVERSE_CONTAINER"

# Wait for the dataverse container to have a responsive API before initiating reExportAll
wait_for_dataverse_up() {
  set +e  # Disable exit-on-error
  while true; do
    STATUS_CODE=$(docker exec "$DATAVERSE_CONTAINER" curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/info/version)
    if [[ "$STATUS_CODE" =~ ^[0-9]+$ ]] && [ "$STATUS_CODE" -eq 200 ]; then
      echo "Dataverse is up."
      break
    else
      echo "Still waiting... (HTTP $STATUS_CODE)"
      sleep 5
    fi
  done
  set -e  # Re-enable exit-on-error
}
echo "Waiting for dataverse container to have a responsive API before continuing..."
wait_for_dataverse_up

# set the jvm options for the exporter plugin to find the config files
# this is done in the dataverse docker container configuration, so we don't need to do it here, but we can print a reminder
#
# Note that this needs to be set in the docker-compose
echo ""
echo "Reminder for if it does not work: set the JVM options for the exporter plugin: -Ddataverse.dcat3.config=/dv/exporters/$DCAT3_CONFIG_DIR/dcat-root.properties"
echo "Manually this can be done with a command like this; replace dataverse_container_name with the actual container name:"
echo "docker exec -it dataverse_container_name asadmin create-jvm-options '-Ddataverse.dcat3.config=/dv/exporters/$DCAT3_CONFIG_DIR/dcat-root.properties'"
echo ""

# Mention that if the DCAT3 output changed you must clear the cached exports by starting a reExportAll
echo "NOTE: "
echo "If the DCAT-AP output changed, you must clear the cached exports by starting a reExportAll. "
echo "You can do this with a command like this; replace dataverse_container_name with the actual container name:"
echo "docker exec -it dataverse_container_name curl http://localhost:8080/api/admin/metadata/reExportAll?exporter=dcat3"
echo ""


# Get back to where we were
cd "$CURRENT_DIR" || exit 1