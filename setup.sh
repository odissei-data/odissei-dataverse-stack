#!/usr/bin/env sh
#
# This script contains a number of setup actions which help prepare the dataverse and Skosmos environments.

# Setting up submodules and creating the traefik network.
git submodule init && git submodule update
docker network create traefik

# Setting up solr; including it in docker network and loading our config
cp Skosmos/dockerfiles/config/config-docker-compose.ttl utils/skosmos/config-docker-compose-backup.ttl
cp Skosmos/dockerfiles/docker-compose.yml utils/skosmos/docker-compose-backup.yml

cp utils/skosmos/docker-compose-skosmos.ttl Skosmos/dockerfiles/config/config-docker-compose.ttl
cp utils/skosmos/docker-compose.yml Skosmos/dockerfiles/docker-compose.yml

# docker compose -f Skosmos/dockerfiles/docker-compose.yml up -d (Disabled due to jena-fuseki)

# Setting up solr; adding our schema and starting solr. Also adding dataverse to traefik network.

cp dataverse/conf/solr/8.11.1/schema.xml utils/solr/schema-backup.xml
cp utils/solr/schema.xml dataverse/conf/solr/8.11.1/schema.xml
#docker compose -f dataverse/docker-compose-dev.yml up -d (Disabled due to needing manual steps)

# Loading our metadata blocks.

# cp utils/metadata/* utils/Custom-Metadata-Blocks/tsv_files/
# sh utils/Custom-Metadata-Blocks/tsv_files/upload-blocks.sh (Disabled since dataverse needs to boot)

# Starting our traefik configuration.

docker compose -f utils/traefik/docker-compose.yml up -d
