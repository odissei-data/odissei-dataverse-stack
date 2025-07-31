Upgrade from 6.4 to 6.5
========================

This is a simple upgrade, because there are no database schema changes; so no flyway scripts needed. 
Also no changes of the standard metadata blocks, like the citation.tsv or anything else. 

This upgrade is simply using new Postgres, Solr and Dataverse images. 
Needs to dump the database before the upgrade and import it after. 
Then have the Solr index be 'reindexed' with that information from the imported database, which has all settings. 
Some changes must be made, because the GDCC images do not have that; like changing the `dataset.xhtml` file. 

To upgrade run the following from the project dir using sudo; which is needed to wipe the volumes: 

```
sudo utils/upgrades/6.4to6.5/upgrade.sh
```

Configuration via .env
----------------------

Could not use the corresponding base image;
`BASE_IMAGE=gdcc/base:6.5-noble`, did not work, needed to use the latest; 
`BASE_IMAGE=gdcc/configbaker:unstable`. 
Also the Solr version that is in 6.4 (9.4.1) did not work; 
Using it gives `java.lang.ClassNotFoundException: solr.NumFieldLimitingUpdateRequestProcessorFactory`. 
The newer version did work; `SOLR_VERSION=9.8.0`. 
