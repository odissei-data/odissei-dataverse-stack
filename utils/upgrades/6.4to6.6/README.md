Upgrade from 6.4 to 6.6
========================

As with the pervious upgrade of Dataverse via docker containers, we need a full replacement op both Postgres and Solr. 
Thus the main thing to do is create a database dump and restore it after the 'upgrade' of the containers. 
Then sThe additional changes that Odissei has made and that are not in the database need to be reapplied. 
Last, we need to apply extra changes that are needed for the upgrade as described in the release notes. 

The Solr schema file was retrieved: 
`wget https://raw.githubusercontent.com/IQSS/dataverse/v6.6/conf/solr/schema.xml`.

For 6.6 this is several tsv files; with the changed metadata block definitions. 
Retrieved them: 
- citation.tsv
  `wget https://raw.githubusercontent.com/IQSS/dataverse/v6.6/scripts/api/data/metadatablocks/citation.tsv`
- 3d_objects.tsv
  `wget https://raw.githubusercontent.com/IQSS/dataverse/v6.6/scripts/api/data/metadatablocks/3d_objects.tsv`

Also we need to change the language translations (properties files) for those blocks.
Retrieved them:
- en_US
  `wget https://raw.githubusercontent.com/GlobalDataverseCommunityConsortium/dataverse-language-packs/dataverse-v6.6/en_US/citation.properties`
  `wget https://raw.githubusercontent.com/GlobalDataverseCommunityConsortium/dataverse-language-packs/dataverse-v6.6/en_US/3dobjects.properties`
- nl_NL
  Those need to be created by us, or anoyone translating them to Dutch ...
  When we don't have it just use the english (default) ones. 
  For the citation, there was only one property added, so that can be simple. 
  `controlledvocabulary.authorIdentifierScheme.ror=ROR`
  The 3d_objects is new, so we would need to translate all of that

To upgrade run the following from the project dir using `sudo`; which is needed to wipe the volumes: 

```
sudo utils/upgrades/6.4to6.6/upgrade.sh
```

