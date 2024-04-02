#!/usr/bin/env sh
#
# This file takes care to copy the solr config to the correct location and rebooting the container.
#

docker cp schema.xml dev_solr:/template/conf/schema.xml
docker cp schema.xml dev_solr:/var/solr/data/collection1/conf/schema.xml
docker cp solrconfig.xml dev_solr:/template/conf/solrconfig.xml
docker cp solrconfig.xml dev_solr:/var/solr/data/collection1/conf/solrconfig.xml
docker restart dev_solr
