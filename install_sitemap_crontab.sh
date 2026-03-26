#!/bin/bash
 
echo "Adding cron job for the Dataverse sitemap generation..."

source .env

# check if DATAVERSE_CONTAINER exists
if [ -z "$DATAVERSE_CONTAINER" ]; then
    echo "No dataverse container specified as environment variable; exiting!"
    exit 1
else
    echo "Using dataverse container from environment variable: $DATAVERSE_CONTAINER"
fi

# print the value of DATAVERSE_CONTAINER into the CRON_JOB variable
CRON_JOB=$(printf "# dataverse sitemap rebuild
0 4 * * * docker exec %s curl -X POST http://localhost:8080/api/admin/sitemap" "$DATAVERSE_CONTAINER")
 
# Check if the job already exists
if crontab -l 2>/dev/null | grep -qF "# dataverse sitemap rebuild"; then
    echo "Cron job already exists, skipping."
    exit 0
fi
 
# Add (append) the job
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
 
echo "Cron job installed successfully."
