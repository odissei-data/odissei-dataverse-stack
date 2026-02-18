#!/bin/bash

# Need the DATAVERSE_CONTAINER in order to restart
if [ -z "$DATAVERSE_CONTAINER" ]; then
  echo "DATAVERSE_CONTAINER environment variable is not set!"
    # check if it was passsed as parameter
    if [ -z "$1" ]; then
        echo "No parameter passed for dataverse container; exiting!"
        exit 1
    else
        DATAVERSE_CONTAINER="$1"
        echo "Using dataverse container from parameter: $DATAVERSE_CONTAINER"
    fi
fi

# Run this from the script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CURRENT_DIR="$(pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "Installing new exporter jar. Script directory: $SCRIPT_DIR"

# The dataverse docker volumes directory relative to this script
DOCKER_VOLUMES_DIR=../../../../dataverse/docker-dev-volumes

# Test if we have the docker volumes directory
if [ ! -d "$DOCKER_VOLUMES_DIR" ]; then
  exit_with_message "No $DOCKER_VOLUMES_DIR directory; exiting!"
fi

EXPORTER_DIR_DST=$DOCKER_VOLUMES_DIR/app/data/exporters

# Check if the exporter directory exist, this is an upgrade; it should be there
if [ ! -d "$EXPORTER_DIR_DST" ]; then
  exit_with_message "No $EXPORTER_DIR_DST directory; exiting!"
fi

# Detect an old jar file and rename it to avoid it is loaded by dataverse. 
# We rename it instead of deleting it just to be safe, but it can be removed if not needed anymore. 
# Note that the old jar file will not be loaded by dataverse as long as it doesn't have the .jar extension, 
# so we rename it to have a .old extension.
OLD_JAR_FILE=croissant-0.1.5.jar
if [ -f "$EXPORTER_DIR_DST/$OLD_JAR_FILE" ]; then
  echo "Renaming old jar file: $OLD_JAR_FILE"
  mv "$EXPORTER_DIR_DST/$OLD_JAR_FILE" "$EXPORTER_DIR_DST/$OLD_JAR_FILE.old"
fi

# Copy the jar files from src to dst
NEW_JAR_FILE=./croissant-0.1.6.jar
if [ ! -f "$NEW_JAR_FILE" ]; then
  echo "No $NEW_JAR_FILE file; exiting!"
  exit_with_message "No $NEW_JAR_FILE file; exiting!"
fi

echo "Copying $NEW_JAR_FILE file to $EXPORTER_DIR_DST"
cp "$NEW_JAR_FILE" $EXPORTER_DIR_DST/

# You must restart the dataverse container to load the new exporter(s).
echo "Restarting dataverse container to load the new exporter(s)..."
docker restart "$DATAVERSE_CONTAINER"

# Wait for the dataverse container to have a responsive API before initiating reExportAll
wait_for_dataverse_up() {
    local max_retries="${1:-24}" # Default to 24 retries (2 minutes if we wait 5 seconds between retries)
    local retries=0
    while true; do
        VERSION_STATUS_CODE=$(docker exec "$DATAVERSE_CONTAINER" curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/info/version)

        if [ "$VERSION_STATUS_CODE" -eq 200 ]; then
            echo "Dataverse API is up."
            break
        else
            retries=$((retries + 1))
            if [ "$retries" -ge "$max_retries" ]; then
                echo "Max retries ($max_retries) reached. Dataverse API is still not up."
                exit_with_message "Dataverse API did not become responsive in time; exiting!"
            fi
            echo "Trial $retries of $max_retries: Still waiting... (HTTP $VERSION_STATUS_CODE)"
            sleep 5
        fi
    done
}
# wait for Dataverse to be ready
echo "Waiting for dataverse container to have a responsive API before initiating reExportAll..."
wait_for_dataverse_up 50
# note that it might have failed to come up within the time limit

echo "Initiating reExportAll to update the export format for the new exporter..."
STATUS_CODE_RE_EXPORT_ALL=$(docker exec "$DATAVERSE_CONTAINER" curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/admin/metadata/reExportAll)
# Note that code 202 means accepted for processing, which is what we expect here since reExportAll is an asynchronous process
if [ "$STATUS_CODE_RE_EXPORT_ALL" -eq 202 ]; then
    echo "Dataverse reExportAll started successfully."
else
    echo "Dataverse reExportAll did not start: (HTTP $STATUS_CODE_RE_EXPORT_ALL)"
fi

# function to exit with message
exit_with_message() {
    local message="$1"
    echo "$message"
    # Get back to where we were
    cd "$CURRENT_DIR" || exit 1
    exit 1
}

exit_with_message "Upgrade complete! Please check the dataverse logs to monitor the reExportAll process. Note that it may take a while for all exports to be updated."
