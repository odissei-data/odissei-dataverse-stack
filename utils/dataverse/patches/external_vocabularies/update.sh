#!/bin/bash

# update.sh
#
# description:
# Update the external vocabularies configuration or files
#
# arguments:
# - dataverse container name (can also be set as environment variable)
#
# example call from the root of the project:
# utils/dataverse/patches/external_vocabularies/update.sh dev_dataverse
# 
# This update will just add the files missing for ROR
# NOTE: Because these files were missing, we do not need a browser reload with cache emptying

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

# script files to be copied to the dataverse container
echo "Updating external vocabularies: Adding the files missing for ROR..."

docker cp ../../../../utils/external_vocabularies/cvocutils.js "$DATAVERSE_CONTAINER":/opt/payara/deployments/dataverse/custom/cvocutils.js
docker cp ../../../../utils/external_vocabularies/ror.js "$DATAVERSE_CONTAINER":/opt/payara/deployments/dataverse/custom/ror.js

# cvoc configuration changes must also be applied
echo "Updating external vocabularies: Adding the cvocconf.json file and updating the cvoc configuration in dataverse..."
docker cp ../../../../utils/external_vocabularies/cvocconf.json "$DATAVERSE_CONTAINER":/opt/payara/cvocconf.json
docker exec "$DATAVERSE_CONTAINER" curl -X PUT --upload-file cvocconf.json http://localhost:8080/api/admin/settings/:CVocConf

echo "External vocabularies update complete!"
echo "The ROR will now be visible as links in the dataset metadata"

cd "$CURRENT_DIR" || exit 1
