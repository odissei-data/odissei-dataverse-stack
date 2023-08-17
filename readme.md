# Experimental setup for Dataverse development version

This is a test instance which combines two things:

- The default Skosmos stack
- The development Dataverse stack
- A traefik configuration

The goal of this repo is to reduce the code footprint of ODISSEI, while maximising the code (re-)usage of other solutions.

At the present date, a number of manual steps are (unfortunately) still required. These are listed below, and commented out in the script.

## Setup

1. Run the setup.sh script. This copies all the files to the corresponding locations.

Now get to manual steps.

## (17-08-2023) Fix dataverse docker file.

1. Copy `utils/dataverse/mount` to the root folder of the dataverse directory
2. Add the following lines to the dataverse container under dataverse volumes:

```
      # Specific ODISSEI mounts
      - ./mounts/accessFilesFragment.xhtml:/opt/payara/deployments/dataverse/accessFilesFragment.xhtml
      - ./mounts/dataset.xhtml:/opt/payara/deployments/dataverse/dataset.xhtml
      - ./mounts/dataverse_footer.xhtml:/opt/payara/deployments/dataverse/dataverse_footer.xhtml
      - ./mounts/bundle.Properties:/opt/payara/deployments/dataverse/WEB-INF/classes/propertyFiles/Bundle.properties
      - ./mounts/search-include-fragment.xhtml:/opt/payara/deployments/dataverse/search-include-fragment.xhtml

```
3. Add all containers to traefik network
4. Update `.env` to use tag for dataverse to `alpha` version (otherwise it'll be unstable)
4. Start containers normally

