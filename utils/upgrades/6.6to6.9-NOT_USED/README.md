Upgrade from 6.6 to 6.9
========================

As with the pervious upgrade of Dataverse via docker containers, we need a full replacement op both Postgres and Solr. 
Thus the main thing to do is create a database dump and restore it after the 'upgrade' of the containers. 
Then The additional changes that ODISSEI has made and that are not in the database need to be reapplied. 
Last, we need to apply extra changes that are needed for the upgrade as described in the release notes. 

These can be found  at: https://github.com/IQSS/dataverse/releases/tag/v6.9
Note tha you also ned to read the ones in between; 6.8, 6.7.1 and 6.7. 

The versions for the docket compose (via that .env) can be found here: 
https://github.com/IQSS/dataverse/blob/v6.9/.env

The Solr schema file was retrieved: 
`wget https://raw.githubusercontent.com/IQSS/dataverse/v6.9/conf/solr/schema.xml`.
The config: 
`wget https://raw.githubusercontent.com/IQSS/dataverse/v6.9/conf/solr/solrconfig.xml`.

For 6.9 this is one tsv file; with the changed metadata block definitions. 
Retrieved them: 
- citation.tsv
  `wget https://raw.githubusercontent.com/IQSS/dataverse/v6.9/scripts/api/data/metadatablocks/citation.tsv`


Also we need to change the language translations (properties files) for those blocks.
Retrieved them:
- en_US
  `wget https://raw.githubusercontent.com/GlobalDataverseCommunityConsortium/dataverse-language-packs/dataverse-v6.8/en_US/citation.properties`
  Note that `6.8`, because it was a change on that version. 
- nl_NL
  Those need to be created by us, or anyone translating them to Dutch ...
  When we don't have it just use the english (default) ones. 
  For the citation, there was only a change of two properties, so that can be simple. 
  `controlledvocabulary.language.magi` and `controlledvocabulary.language.magiyi`. 

Note that these changes should also be done in the translation (submodule) at: https://github.com/odissei-data/TranslationDataverseUI


To upgrade run the following from the project dir using `sudo`; which is needed to wipe the volumes: 

```
sudo utils/upgrades/6.6to6.9/upgrade.sh
```

