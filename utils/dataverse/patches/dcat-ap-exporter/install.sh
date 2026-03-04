#!/usr/bin/env sh
#
# install the DCAT-AP exporter plugin
# downloaded from 
#  https://repo1.maven.org/maven2/io/gdcc/dcat-3/v0.8.3/dcat-3-v0.8.3.jar
#
# The 'caller' must restart the dataverse container to load the new exporter(s).


# Assuming we have Datavesre setup with exporter plugins directory configured already

# we have the jar file here, so we can copy it
# Finally this will be done in the existing install_exporters.sh script

# Run this from the script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CURRENT_DIR="$(pwd)"
cd "$SCRIPT_DIR" || exit 1


JAR_FILE=./dcat-3-0.1.1-SNAPSHOT.jar

### Almost copy paste the jar file copying from that other script

echo "Installing exporter jar files. Script directory: $SCRIPT_DIR"

# The dataverse docker volumes directory relative to this script
# this is different, extra two dirs up!
DOCKER_VOLUMES_DIR=../../../../dataverse/docker-dev-volumes

# Test if we have the docker volumes directory
if [ ! -d "$DOCKER_VOLUMES_DIR" ]; then
  echo "No $DOCKER_VOLUMES_DIR directory; exiting!"
  # Get back to where we were
  cd "$CURRENT_DIR" || exit 1
  exit 1
fi

EXPORTER_DIR_SRC=.
EXPORTER_DIR_DST=$DOCKER_VOLUMES_DIR/app/data/exporters

# Create the destination directory if it doesn't exist
if [ ! -d "$EXPORTER_DIR_DST" ]; then
  echo "Creating exporter dir: $EXPORTER_DIR_DST"
  mkdir -p $EXPORTER_DIR_DST
fi

# Copy all *.jar files from src to dst
# echo "Looking for *.jar files in $EXPORTER_DIR_SRC:"
# ls -1 $EXPORTER_DIR_SRC | grep .jar || echo "No .jar files found in $EXPORTER_DIR_SRC"
# echo "Copying *.jar files to $EXPORTER_DIR_DST"
# cp $EXPORTER_DIR_SRC/*.jar $EXPORTER_DIR_DST/

# NOT sure we should copy all, maybe we even have to rename the old one???

# copy the specific jar file we want, and check if it exists
if [ -f "$JAR_FILE" ]; then
  echo "Copying $JAR_FILE to $EXPORTER_DIR_DST"
  cp "$JAR_FILE" "$EXPORTER_DIR_DST/"
else
  echo "No $JAR_FILE file found; exiting!"
  # Get back to where we were
  cd "$CURRENT_DIR" || exit 1
  exit 1
fi




### Extra; also copy that config directory
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

# set the jvm options for the exporter plugin to find the config files
# this is done in the dataverse docker container configuration, so we don't need to do it here, but we can print a reminder
#
# Note that this needs to be set in the docker-compose
echo "Reminder: set the JVM options for the exporter plugin: -Ddataverse.dcat3.config=/dv/exporters/$DCAT3_CONFIG_DIR/dcat-root.properties"
echo "Manually this can be done with a command like this (replace dataverse_container_name with the actual container name):"
echo "docker exec -it dataverse_container_name asadmin create-jvm-options '-Ddataverse.dcat3.config=/dv/exporters/$DCAT3_CONFIG_DIR/dcat-root.properties'"
echo ""

# The 'caller' must restart the dataverse container to load the new exporter(s).
echo "Note that you must restart the dataverse container to load the new exporter(s)."
echo "You can do this with a command like this (replace dataverse_container_name with the actual container name):"
echo "docker restart dataverse_container_name"


# Get back to where we were
cd "$CURRENT_DIR" || exit 1