#!/usr/bin/env sh
#
# This script copies all exporter jar files from utils/dataverse/exporters to the dataverse docker volume
# so that they are available to the dataverse application.
#
# The 'caller' must restart the dataverse container to load the new exporter(s).

# Run this from the script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CURRENT_DIR="$(pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "Installing exporter jar files. Script directory: $SCRIPT_DIR"

# The dataverse docker volumes directory relative to this script
DOCKER_VOLUMES_DIR=../../dataverse/docker-dev-volumes

# Test if we have the docker volumes directory
if [ ! -d "$DOCKER_VOLUMES_DIR" ]; then
  echo "No $DOCKER_VOLUMES_DIR directory; exiting!"
  # Get back to where we were
  cd "$CURRENT_DIR" || exit 1
  exit 1
fi

EXPORTER_DIR_SRC=./exporters
EXPORTER_DIR_DST=$DOCKER_VOLUMES_DIR/app/data/exporters

# Create the destination directory if it doesn't exist
if [ ! -d "$EXPORTER_DIR_DST" ]; then
  echo "Creating exporter dir: $EXPORTER_DIR_DST"
  mkdir -p $EXPORTER_DIR_DST
fi

# Copy al *.jar files from src to dst
echo "Looking for *.jar files in $EXPORTER_DIR_SRC:"
ls -1 $EXPORTER_DIR_SRC | grep .jar || echo "No .jar files found in $EXPORTER_DIR_SRC"
echo "Copying *.jar files to $EXPORTER_DIR_DST"
cp $EXPORTER_DIR_SRC/*.jar $EXPORTER_DIR_DST/

# The 'caller' must restart the dataverse container to load the new exporter(s).
echo "Note that you must restart the dataverse container to load the new exporter(s)."

# Get back to where we were
cd "$CURRENT_DIR" || exit 1
