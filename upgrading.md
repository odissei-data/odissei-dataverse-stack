Upgrading Dataverse
===================

Introduction
------------

The ODISSEI portal is just a Dataverse archiving system, configured to the needs of ODDISEI. It is different from the standard setup of a Dataverse archive in that it does not store real data files, but only has the metadata of datasets stored elsewhere. We could call it an aggregated 'metadata only' archive. 

The portal service deployment is using the docker container setup from Dataverse (with images from GDCC). There is a 'guide' for this container setup https://guides.dataverse.org/en/latest/container/index.html where you can find most information about the use of containers for Dataverse. The initial purpose of those containers is to help in development of the Dataverse software, however we use them for serving of our portal. 

This Github project is not meant to be used for developing Dataverse, instead we use it to support maintenance of the portal by providing an environment that has all the services, but runs them locally. Using this we can test our automation scripts for setup, configuration and upgrading tasks without changing our live servers. 
The complete 'setup' of this environment is done by the `setup.sh` script in the root of this project. It will start the docker containers using docker compose with some of our own configuration setting. Then it will apply more changes that we need for ODISSEI, like branding and other configuration. Details of that setup are described in the  [`readme.md`](./readme.md) of this Github project. By changing the configuration via environment variables, the setup can be run on different servers as well. 
Also, the provided 'utility' scripts (in `utils`) used by the setup, could be run separately enabling to change a running system. 

The setup does only produce an ODISSEI portal (Dataverse archive) without any datasets (metadata). There is another system (ingestion workflow orchestrator) that aggregates all the dataset metadata and imports it into the portal. This Github repo does not provide for that system, so when starting with a fresh (new) portal we have to make that system to repopulate it by re-import all the aggregated dataset metadata into it. The ingestion workflow orchestrator repo is here https://github.com/odissei-data/ingestion-workflow-orchestrator where you should be able to find more information. 

Upgrading is an important part of maintenance because it fixes bugs and adds new useful features. The scripts in this Github repo support the upgrading process. 
You could use the 'setup' and restart from 'scratch'. In this scenario we would 'only' need to change the configuration to start with that new version, using the newer docker images. This can be seen as a 'fallback' scenario when trying to upgrade to a new portal using a newer Dataverse version. The downside of this approach is that we need to repopulate the archive, which will take time, during which the portal is not providing all that is needed. 

Instead of wiping everything, we can run a setup process with those new docker images, but keep as much data as possible. 
In case of a database system upgrade (Postgres) we can restore a database dump and thus keep all metadata. Then reapply any system changes that where not persistent in the database and also apply changes needed for this specific upgrade; specified in the release notes of that new Dataverse version. 

## Supported upgrades

Supported upgrades can be found in the `utils/upgrades` directory which contains sub-dirs for specific version upgrades, like `6.4to6.6` for example. All the information needed for that specific upgrade should be there, with a accompanying `README.md`, explaining some of the details. As noted before, some of those 'utility' scripts (or fragments of it) can be reused. 


## Starting with a new upgrade

The following steps for having a new upgrade will be described in more detail in the next sections: 
1. Implement the upgrade script(s) and test them on this dev environment.
2. Upgrade (and test) on the staging server, fix any bugs (and repeat on dev?).
3. Upgrade the production server
4. Change the dev 'setup' so that it now starts that new version


### Implement the upgrade

Most of the work and time will be spent in this initial step, where you start with your scripts, test and improve, and repeat the process. But, before coding, there are some important pieces of information to figure out. 

#### Gather information about the upgrade

- Read the Datverse release notes, when going from 6.4 to 6.6, also read the versions in between; 6.5 in this case.  (notes are found here)
  - Pay special attention to changes for the sub services; Postgres and Solr. Do we need a upgrade for those? We use the containers, so focus on that. However, those docker images seem to change with almost every Dataverse upgrade. Probably because it is simple to do so. 
  (look here what the docker compose tells you)
  We can disregard Payara upgrades, we get a new Payara just by using that new dataverse container. 
  - Look for changes or additions of metadat blocks, defined in those TSV files, like the mandatory `citation.tsv`. 
  - Look for changes of the Solr `schema.xml`, some changes or additins in metdata do need changes for that as well. 
  - Check the suggestions to run a Solr `index`, we might need to do that, most likely if the Solr schema changed. But if we upgrade Solr we need to do it anyway. 
  - Check the suggestions to run a `reExportAll`, we might need to do that. 
  - We can ignore suggestions to notice (send updates to) DataCite because we do not register PIDS. 
  - New options or features, maybe we want to use them and if so, maybe we nee dto change some config to 'enable' them. 
- Inspect previous upgrades, what is similar enough so we can copy paste?

#### Create a new sub-dir for this upgrade
 and populate it with. As a convention, have  the `upgrade.sh` script as your main script. Have a `README.md` file, where we can explain the details of this specific upgrade. Preferably put files that are for 'sub tasks', like this metadata upgrades in their own sub-dirs.  

#### Start your development cycle
 Create the `dot_env_<new version>` file for that new version, you should have gathered that information. Create the initial version of the `upgrade.sh` file, it only has to result in a default - as-is - running Dataverse (new) version. 
 For this the script should; bring down the containers, copy that dot_env and then bring the containers up with that env. 
 Minimal testing would then be to check the version (in the footer) and to login and add a dataset and publish it. Note that we would not want to publish on a production server. 
 Add more complexity to the script and keep it working. If you are confident you might just copy a whole previous upgrade and just edit that. But remember, if things do not work out, simply start with that minimal initial script as described before. 
 
To test with a 'local' dev environment (in the project root dir). 
1. Start with an 'old' version running, you can setup a fresh one with this:
     ```
   ./teardown_and_cleanup_submodules.sh 
   sudo rm -rf ./dataverse/docker-dev-volumes
   Then start it
   ./setup.sh
     ```
2.  Login and create a Dataset, if there is none yet. Publish and logout, check that the Dataset is visible in the search results. We then assume the current situation is working correct with respect to mutating the database and search index. Note that we don't have to test every time if the `setup.sh` does not change. 
3. Run the upgrade script (type the sudo password when asked for it):
   ```
   sudo utils/upgrades/<old version>to<new version>/upgrade.sh
   ```
4. Check that the dataverses and that dataset(s) are there. Note that the in the 'minimal' initial upgrading script, we expect an empty archive.  
5. Check that you can create an new dataset and that it can be published and is properly indexed.  and you can view a dataset landingpage. 

#### Trouble shooting

1. Read the screen (output). This is obvious, but many times after finding and fixing some problem, re-reading the console output revealed that the answer was there all the time.   

2. Look at the logs, mostly dev_dataverse, but solr or postgresql might also be useful. Use `docker logs` optionally with the `--follow` option, so you can se the results of your actions immediately. 

3. Check the database, especially the flyway table or the dvobjects table. 
   For example: 
   ```
   docker exec -i dev_postgres psql -U dataverse -d dataverse -t -c "SELECT * FROM flyway_schema_history;"
   ```
   With every new version of Dataverse these 'flyway' SQL scripts are used to update the database if needed. A restart of the container or restart of the Payara domain will initiate this. 
   If need you can try restarting the domain like this: 
   ```
   docker exec -i dev_dataverse /bin/bash -c "/opt/payara/appserver/glassfish/bin/asadmin restart-domain domain1"
   ```
   Check those SQL files in the Github repository. For instance, with the 6.5 version the are here: https://github.com/IQSS/dataverse/tree/v6.5/src/main/resources/db/migration. 


### Upgrade the staging server

Run that upgrade script. 
If something goes wrong we can not simply downgrade and start over again. We could wipe it and start from scratch, but that will take some time and we don't have the same situation unless we also repopulate the metadata. 
Whatever we do to fix it, we need to get those fixes into the scripts and retest on the dev environment. 


### Upgrade production server

Run that upgrade script, so this is similar to upgrading the staging server. The difference is that, if it goes wrong, users might not be able to use it while we are fixing it.  

### Change the dev setup

After evrything is upgraded we need to change the setup script to deliver a clean dev setup of that new version. The `dot_env` content must be updated, and if there was a `schema.xml` change, we must update this as well. Other files could be those TSV files and properties files for the metadata blocks. 

Do not forget to check those submodules: `Custom-Metadata-Blocks` and `translations`. Do they need upgrading via the Github repos?
