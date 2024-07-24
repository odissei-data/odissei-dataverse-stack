#!/bin/bash

container_name=$1

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CURRENT_DIR="$(pwd)"

cd "$SCRIPT_DIR" || exit 1

docker cp upload-blocks.sh "$container_name":/opt/payara/
docker cp . "$container_name":/opt/payara/
docker exec -it "$container_name" chmod +x /opt/payara/upload-blocks.sh
docker exec -it "$container_name" sh /opt/payara/upload-blocks.sh

cd "$CURRENT_DIR" || exit 1
