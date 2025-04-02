#!/usr/bin/env sh
#
# This script takes care to fix the robots.txt file in the Dataverse installation.

if [ -z "$HOSTNAME" ]; then
  echo "Please set the HOSTNAME environment variable to the hostname of the server."
  exit 1
fi
if [ $# -ne 1 ]; then
  echo "Usage: $0 <dataverse_container_name>"
  exit 1
fi
dataverse_container_name=$1

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CURRENT_DIR="$(pwd)"

echo "Fixing robots.txt file in dataverse container $dataverse_container_name Script directory: $SCRIPT_DIR"

cd "$SCRIPT_DIR" || exit 1

# Only allow some crawling on production 
# Nothing special on the staging server, so we can just use the dev.robots.txt file
if [ "$HOSTNAME" = "odissei.nl" ]; then
  echo "Copying production robots.txt file to dataverse container"
  docker cp robots-txt/prod.robots.txt "$dataverse_container_name":/opt/payara/deployments/dataverse/robots.txt
else
  echo "Copying development robots.txt file to dataverse container"
  docker cp robots-txt/dev.robots.txt "$dataverse_container_name":/opt/payara/deployments/dataverse/robots.txt
fi 

cd "$CURRENT_DIR" || exit 1
