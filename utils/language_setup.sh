#!/bin/bash

container_name=$1
docker exec "$container_name" curl http://localhost:8080/api/admin/settings/:Languages -X PUT -d '[{"locale":"en","title":"English"},{"locale":"nl","title":"Nederlands"}]'
docker exec "$container_name" mkdir langBundles
docker exec -it "$container_name" asadmin create-jvm-options '-Ddataverse.lang.directory=/opt/payara/langBundles'
docker cp translations/en_US/. "$container_name":/opt/payara
docker cp translations/nl_NL/. "$container_name":/opt/payara
docker exec -it -u 0 "$container_name" apt-get update
docker exec -it -u 0 "$container_name" apt-get install -y zip
docker exec "$container_name" sh -c "find . -name '*.properties' | zip languages.zip -@"
docker exec "$container_name" curl http://localhost:8080/api/admin/datasetfield/loadpropertyfiles -X POST --upload-file /opt/payara/languages.zip -H "Content-Type: application/zip"