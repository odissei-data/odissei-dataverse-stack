# ODISSEI Dataverse setup

The Dataverse stack for the ODISSEI portal. provides a quick setup for the Dataverse stack used for the ODISSEI Portal. 

- The Dataverse stack
- A traefik configuration

The goal of this repo is to reduce the code footprint of ODISSEI, while maximising the code (re-)usage of other solutions.
For upgrading an existing system, read the [`upgrading.md`](upgrading.md) document. 

At the present date, a number of manual steps are still required. These are listed below, and commented out in the script.

## Setup

### Install Poetry

Run the following commands:

```bash
curl -sSL https://install.python-poetry.org | python3 -
```

Add Poetry to your system path:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Verify the installation:

```bash
poetry --version
```

### Steps
1. Setup Poetry and Python
2. Install docker (obviously)
3. Ensure ports are open where they need to be.
4. `cp dot_env_example .env` - make changes to the .env if necessary. 
   For instance, when running on a local machine make sure you have `ROOT_URL="http://localhost:8080"`. 
5. Run the setup.sh script: `./setup.sh`.

## Setup script
The setup script does the following things for you:
1. Sets the variables in the .env file as environmental variables.
2. Initiates and update the submodules.
3. Copies the docker-compose and .env to the Dataverse submodule.
4. Creates the traefik network the containers will be using.
5. Ups both the Dataverse and Traefik containers.
6. Waits for Dataverse to be finished setting up.
7. Runs a script that loads in the custom metadata blocks.
8. Runs a script that imports the licenses and sets up the subverses.
9. Runs a script that sets up the Dutch translation.
10. Runs a script that copies and sets up the SOLR schema and config.
11. Turns off the sign up option.
12. Sets the changed version of the dataset page and restart the Dataverse container.

## Manual steps (optional)

After the setup script has run the 'dev' portal is not completely identical to the production. Some steps are simpler to do 'manually' instead of using scripts. But this may change over time as more is being automated. 

There are now several 'steps' that need to be done: 

1. Fix the portal 'theme'. 
   Use the files and instruction (`Settings_and_ColorCodes.md`) in the `utils/dataverse/theme` directory to change the site logo and other things. 
2. Fix the logos for the data providers in their sub-verses. 
   Upload them from the `utils/dataverse/dataverses/logos` directory. 
   Note that we do not use logos for the DataverseNL sub-verses.
3. Remove the ‘Add Data’ button on the menu bar. 
   Change the root dataverse permissions: From ' Anyone with an account can add a dataverse or dataset' into ‘Anyone adding to this dataverse needs to be given access’. And then the button in the navbar will disappear.


## Cleanup for Commits and Pull Requests

The following files are overwritten by copy actions in the setup.sh script. 
We can't ignore them via the .gitignore and also not in the respective submodules. 
These changes must be ignored manual, by reverting or only selecting the other changes when committing. 

Copied the docker-compose:
`dataverse/docker-compose.yml`

Copied metadata block scripts:
`utils/Custom-Metadata-Blocks/tsv_files/upload.sh`
`utils/Custom-Metadata-Blocks/tsv_files/upload-blocks.sh`

Cleanup is automated by running the following script:
```
./teardown_and_cleanup_submodules.sh
```

Note that if you want to have a fresh start the next time you run the setup, you need to wipe the persistent volumes:
```
sudo rm -rf dataverse/docker-dev-volumes
```
