Payara asadmin scripts
======================

These are helper scripts to circumvent the interactive command with the user needing to enter the `asadmin` credentials.

The `asadmin` command allows to specify a password file, 
that contains the password and therefore does not need to be specified interactively (with the shell prompt). 

The script must be available on the container, where the password is available as environment variable. 

When running scripts to upgrade of fix something we do not want this interactive stuff, because it breaks unsupervised automation; a human is needed to enter credentials. 

JVM options should be specified in the docker-compos.yml via the `JVM_ARGS` value. 
But if we want to change something on a system without having to reevaluate that docker-compose, we like those `asadmin` commands. 
Rebuilding the container results in some missing steps that we have to fix then, because automation for the portal is not fully implemented yet!


As an example the `list-jvm-options` command

1. Copy the script file: 

   ```
   cp asadmin-list-jvm-options.sh ../../../dataverse/docker-dev-volumes/app/data/
   ```

2. Then it can be run via `docker exec` as a bash script: 

   ```
   docker exec dev_dataverse bash /dv/asadmin-list-jvm-options.sh
   ```

There is an install script (`install.sh`) that will do those copies. 
