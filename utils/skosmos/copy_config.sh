#!/usr/bin/env sh
#
# Takes care to substitute the Skosmos file in place.

cp ../../Skosmos/dockerfiles/config/config-docker-compose.ttl ../../distros/Skosmos/dockerfiles/config/config-docker-compose-backup.ttl
cp ../../Skosmos/dockerfiles/docker-compose.yml ../../distros/Skosmos/dockerfiles/docker-compose-backup.yml

cp docker-compose-skosmos.ttl ../../Skosmos/dockerfiles/config/config-docker-compose.ttl
cp docker-compose.yml ../../Skosmos/dockerfiles/docker-compose.yml
docker exec -it restart skosmos
