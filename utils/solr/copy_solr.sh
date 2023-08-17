#!/usr/bin/env sh
#
# This file takes care to copy the solr config to the correct location and rebooting the container.

cp ../../dataverse/conf/solr/8.11.1/schema.xml schema-backup.xml
cp schema.xml ../../dataverse/conf/solr/8.11.1/schema.xml
docker restart solr
