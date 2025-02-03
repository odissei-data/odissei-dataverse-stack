# Experimental setup for Dataverse development version

This is a test instance which combines two things:

- The default Skosmos stack
- The development Dataverse stack
- A traefik configuration

The goal of this repo is to reduce the code footprint of ODISSEI, while maximising the code (re-)usage of other solutions.

At the present date, a number of manual steps are (unfortunately) still required. These are listed below, and commented out in the script.

## Setup

1. Install the `raptor2-utils` library on your machine. You need this for the conversion of rdf to ttl for Skosmos.
2. Install docker (obviously)
3. Ensure ports are open where they need to be.
4. `cp dot_env_example .env` - make changes to the .env if necessary.
5. Run the setup.sh script.

Now get to manual steps.

## Setup script
The setup script does the following things for you:
1. Sets the variables in the .env file as environmental variables.
2. Initiates and update the submodules.
3. Copies docker-compose and config for Skosmos to the Skosmos submodule.
4. Copies the docker-compose and .env to the Dataverse submodule.
5. Creates the traefik network the containers will be using.
6. Ups both the Skosmos, Dataverse and Traefik containers.
7. Waits for Dataverse to be finished setting up.
8. Runs a script that loads in the custom metadata blocks.
9. Runs a script that imports the licenses and sets up the subverses.
10. Runs a script that sets up the Dutch translation.
11. Runs a script that copies and sets up the SOLR schema and config.
12. Turns off the sign up option.
13. Sets the changed version of the dataset page and restart the Dataverse container.

