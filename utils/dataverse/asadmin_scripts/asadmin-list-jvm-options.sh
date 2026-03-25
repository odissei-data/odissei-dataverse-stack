#!/bin/bash

# Run the asadmin list-jvm-options command. 
#
# In order to prevent interactivity entering username and password
# the 'passwordfile' option of asadmin is used. 
# the credentials are available in the container as environment variables, 
# so we can use those to create a temporary password file for asadmin

PASSWORD_FILE=$(mktemp)
echo "AS_ADMIN_PASSWORD=$PAYARA_ADMIN_PASSWORD" > "$PASSWORD_FILE"

OUTPUT=$(asadmin --user="${PAYARA_ADMIN_USER}" --passwordfile="$PASSWORD_FILE" list-jvm-options)
STATUS=$?
rm "$PASSWORD_FILE"
if [ "$STATUS" -ne 0 ]
  then
    echo ERROR: "$OUTPUT" >&2
    exit 1
fi
# show output
# should end with: Command list-jvm-options executed successfully.
echo "$OUTPUT"