#!/bin/bash
# copy the files into the persistent volumes

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CURRENT_DIR="$(pwd)"

cd "$SCRIPT_DIR" || exit 1

# make sure it continues even if there is an error, we want to cd back
#set +e
cp asadmin-list-jvm-options.sh ../../../dataverse/docker-dev-volumes/app/data/
cp asadmin-create-jvm-options.sh ../../../dataverse/docker-dev-volumes/app/data/
cp asadmin-delete-jvm-options.sh ../../../dataverse/docker-dev-volumes/app/data/
#set -e

cd "$CURRENT_DIR" || exit 1