#!/bin/bash

# Run the asadmin create-jvm-options command. 
#
# In order to prevent interactivity entering username and password
# the 'passwordfile' option of asadmin is used. 
# the credentials are available in the container as environment variables, 
# so we can use those to create a temporary password file for asadmin

# Get the JVM options from the command line arguments and pass them to the create-jvm-options command.
JVM_OPTIONS="$@"
  

PASSWORD_FILE=$(mktemp)
echo "AS_ADMIN_PASSWORD=$PAYARA_ADMIN_PASSWORD" > "$PASSWORD_FILE"

OUTPUT=$(asadmin --user="${PAYARA_ADMIN_USER}" --passwordfile="$PASSWORD_FILE" create-jvm-options $JVM_OPTIONS)
STATUS=$?
rm "$PASSWORD_FILE"
if [ "$STATUS" -ne 0 ]
  then
    echo ERROR: "$OUTPUT" >&2
    exit 1
fi
# show output
# should end with: Command create-jvm-options executed successfully.
#
# Note that if the exact same options already exist, 
# the command will fail with an error message like: "Error: JVM option already exists: <option>"
echo "$OUTPUT"