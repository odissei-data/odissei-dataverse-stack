#!/bin/bash
# This script copies all exporter jar files from utils/dataverse/exporters to the dataverse docker volume
# so that they are available to the dataverse application.
# The script must be run from the root of the repository.
# The 'caller' must restart the dataverse container to load the new exporter(s).
set -e

# Check that we have dataverse/docker-dev-volumes/app/data
if [ ! -d "./utils/dataverse/docker-dev-volumes/app/data" ]; then
  echo "Please run this script from the root of the repository."
  exit 1
fi

EXPORTER_DIR_SRC=./utils/dataverse/exporters
EXPORTER_DIR_DST=./utils/dataverse/docker-dev-volumes/app/data/exporters

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
