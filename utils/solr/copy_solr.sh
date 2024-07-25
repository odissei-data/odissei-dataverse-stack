#!/bin/bash
#
# This file takes care to copy the solr config to the correct location and rebooting the container.
#

solr_container_name=$1

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CURRENT_DIR="$(pwd)"

cd "$SCRIPT_DIR" || exit 1

docker cp schema.xml "$solr_container_name":/template/conf/schema.xml
docker cp schema.xml "$solr_container_name":/var/solr/data/collection1/conf/schema.xml
docker cp solrconfig.xml "$solr_container_name":/template/conf/solrconfig.xml
docker cp solrconfig.xml "$solr_container_name":/var/solr/data/collection1/conf/solrconfig.xml
docker restart "$solr_container_name"

cd "$CURRENT_DIR" || exit 1
