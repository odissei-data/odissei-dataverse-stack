#!/bin/bash

dataverse_container_name=$1
docker exec "$dataverse_container_name" curl http://localhost:8080/api/admin/settings/:Languages -X PUT -d '[{"locale":"en","title":"English"},{"locale":"nl","title":"Nederlands"}]'
docker exec "$dataverse_container_name" mkdir langBundles
docker exec -it "$dataverse_container_name" asadmin create-jvm-options '-Ddataverse.lang.directory=/opt/payara/langBundles'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CURRENT_DIR="$(pwd)"

cd "$SCRIPT_DIR" || exit 1

docker cp translations/en_US/. "$dataverse_container_name":/opt/payara
docker cp translations/nl_NL/. "$dataverse_container_name":/opt/payara

cd "$CURRENT_DIR" || exit 1

docker exec -it -u 0 "$dataverse_container_name" apt-get update
docker exec -it -u 0 "$dataverse_container_name" apt-get install -y zip
docker exec "$dataverse_container_name" sh -c "find . -maxdepth 1 -name '*.properties' | zip languages.zip -@"
docker exec "$dataverse_container_name" curl http://localhost:8080/api/admin/datasetfield/loadpropertyfiles -X POST --upload-file /opt/payara/languages.zip -H "Content-Type: application/zip"