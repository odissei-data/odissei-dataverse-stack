#!/usr/bin/env sh
#
# This script takes care to fix the robots.txt file in the Dataverse installation.

# Only allow some crawling on production 
# noting special on the staging server, so we can just use the dev.robots.txt file
if $HOSTNAME == "odissei.nl"; then
  docker cp robots-txt/prod.robots.txt dev_dataverse:/opt/payara/deployments/dataverse/robots.txt
else
  docker cp robots-txt/dev.robots.txt dev_dataverse:/opt/payara/deployments/dataverse/robots.txt
fi 

