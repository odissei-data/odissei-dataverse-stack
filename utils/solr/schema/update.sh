#!/bin/bash

# Updates the Solr configuration; schema.xml
#
# Note that this must be run after the custom metadata blocks are installed (loaded).
# Also this must be run after changes to the metadata blocks are made, 
# so the schema is up to date.

# check if we have the right number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <dataverse_container_name> <solr_container_name>"
    exit 1
fi
DATAVERSE_CONTAINER=$1
SOLR_CONTAINER=$2

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CURRENT_DIR="$(pwd)"

cd "$SCRIPT_DIR" || exit 1

# get the schema file from the solr container
#docker cp "$SOLR_CONTAINER":/var/solr/data/collection1/conf/schema.xml ./schema.xml
# DOESN"T WORK, use the one obtained from IQSS
# for 6.6
#   wget https://raw.githubusercontent.com/IQSS/dataverse/v6.6/conf/solr/schema.xml

# ----

# # copy it to the docker container
# docker cp schema.xml "$DATAVERSE_CONTAINER":/opt/payara/schema.xml
# # also copy that update-fields.sh
# # Note that it was obtained from the dataverse repo: 
# #   wget https://raw.githubusercontent.com/IQSS/dataverse/v6.6/conf/solr/update-fields.sh
# #   chmod +x update-fields.sh
# docker cp update-fields.sh "$DATAVERSE_CONTAINER":/opt/payara/update-fields.sh

# docker exec "$DATAVERSE_CONTAINER" bash -c "curl 'http://localhost:8080/api/admin/index/solr/schema' | ./update-fields.sh /opt/payara/schema.xml"

# # get the result
# docker cp "$DATAVERSE_CONTAINER":/opt/payara/schema.xml ./new-schema.xml

# ---- 

# Sorry we can't run that update-fields.sh on the dev_dataverse container,  
# because it needs 'ed' and bc' ( also 'sed' and 'awk') which are not installed there. 
# Lets get that fields xml file from the dataverse container
# and then run the script here

docker exec "$DATAVERSE_CONTAINER" bash -c "curl 'http://localhost:8080/api/admin/index/solr/schema' > /opt/payara/fields.xml"
docker cp "$DATAVERSE_CONTAINER":/opt/payara/fields.xml ./fields.xml

# check if we have prerequisites installed for that script

# Function to check if a command exists
exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to show an error message and exit
error() {
    echo "ERROR:" "$@" >&2
    exit 2
}

# Check for ed and bc being present, is done in the script, but we need to do it here too
exists ed || error "Please ensure ed, bc, sed + awk are installed"
exists bc || error "Please ensure ed, bc, sed + awk are installed"
exists awk || error "Please ensure ed, bc, sed + awk are installed"
exists sed || error "Please ensure ed, bc, sed + awk are installed"

cp schema.xml new-schema.xml
cat fields.xml | ./update-fields.sh ./new-schema.xml

docker cp new-schema.xml "$SOLR_CONTAINER":/var/solr/data/collection1/conf/schema.xml
# not sure about that next copy...
docker cp new-schema.xml "$SOLR_CONTAINER":/template/conf/schema.xml

# restart the solr container
docker restart "$SOLR_CONTAINER"
# maybe reload is enough, but seems to fail with 'No such core: collection1'
# http://localhost:8983/solr/admin/cores?action=RELOAD&core=collection1
# docker exec "$SOLR_CONTAINER" curl "http://localhost:8983/solr/admin/cores?action=RELOAD&core=collection1"

# Hard re-indexing is simple and most likely not a burden, repo should be almost empty initially
# If the repo has lots of stuff, we should NOT do re-indexing here!
docker exec "$DATAVERSE_CONTAINER" curl http://localhost:8080/api/admin/index

cd "$CURRENT_DIR" || exit 1
