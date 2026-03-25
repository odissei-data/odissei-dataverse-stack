DCAT-AP Exporter plugin
=======================

Installing the DCAT-AP Exporter plugin. 

The plugin code is on the following GitHub repo: https://github.com/gdcc/exporter-dcat3 .

Without building it, the plugin `jar` can be downloaded from a maven repo, for example version 0.8.4 was downloaded (wget) from: 
`https://repo1.maven.org/maven2/io/gdcc/dcat-3/v0.8.4/dcat-3-v0.8.4.jar`. 

__Note:__ when upgrading do not forget to remove the old jar from `dataverse/docker-dev-volumes/app/data/exporters`!

The `install.sh` will install the DCAT-AP Exporter plugin:  

```
sudo utils/dataverse/patches/dcat-ap-exporter/install.sh dev_dataverse
```

The `sudo` and `dev_dataverse` are needed for the docker restart. 

Note that when the exporter is installed for the first time, there is no need to reexport the metadata. 
When there is an upgrade you might want to reexport because the cached exports need to be refreshed. 

You can read about the possibilities for reexporting in the Dataverse guides: https://guides.dataverse.org/en/latest/admin/metadataexport.html

A full reexport: 
```
docker exec dev_dataverse curl http://localhost:8080/api/admin/metadata/reExportAll
```

NOTE: Somehow `clearExportTimestamps` does not seem to help, not sure why, so reExport must be used. 


## Developer notes

When changing the jar file, you must make sure that old version are removed. 
You can see if there are any with the following: 

```
ls -al dataverse/docker-dev-volumes/app/data/exporters/*.jar
```

To remove one you need to use `sudo`. 
 
If you only change the configuration there is no need to manage the jar file. 

Configuration is explained here: https://github.com/gdcc/exporter-dcat3/blob/main/DOCUMENTATION.md


Deploying the jar and config run that `install.sh`: 

```
sudo utils/dataverse/patches/dcat-ap-exporter/install.sh dev_dataverse
```

Most of the time you want to update those cached exports with: 

```
docker exec dev_dataverse curl http://localhost:8080/api/admin/metadata/reExportAll
```

If the archive has many datasets you might want to restrict the re-export to just a single dataset

```
curl 'https://portal.odissei.nl/api/admin/metadata/:persistentId/reExportDataset?persistentId=doi:10.34894/8575OP'
```

Or just the 'dcat3' format: 

```
docker exec -it dev_dataverse curl http://localhost:8080/api/admin/metadata/reExportAll?exporter=dcat3
```




