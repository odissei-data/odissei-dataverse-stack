#!/bin/bash

container_name=$1
docker exec "$container_name" curl http://localhost:8080/api/admin/settings/:Languages -X PUT -d '[{"locale":"en","title":"English"},{"locale":"nl","title":"Nederlands"}]'
docker exec -it "$container_name" asadmin create-jvm-options '-Ddataverse.lang.directory=/opt/payara/langBundles'
docker exec "$container_name" mkdir langBundles
docker cp -R translations/en_US/*.properties "$container_name":/opt/payara
docker cp -R translations/nl_NL/*.properties "$container_name":/opt/payara
docker exec "$container_name" zip languages.zip *.properties
docker exec "$container_name" curl http://localhost:8080/api/admin/datasetfield/loadpropertyfiles -X POST --upload-file /opt/payara/languages.zip -H "Content-Type: application/zip"