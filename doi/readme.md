# DOI - Digital Object Identifier

All files belonging to the DOI support are found under this directory
to avoid fragmenting them within the rest of the TEI-Publisher sourcecode.

Also eases an opt-out build of TEI-Publisher.

upda## Feature description

The DOI feature allows to bulk upload a set of TEI documents and register DOIs for them with the DARA registrar.

### Current Restrictions

The TEI documents must conform to the standards of the "Deutsches Textarchiv" which defines a standard
for the TEI-encoding of certain information. If the incoming document will not conform to these rules only
default values can be set for the DOI metadata.

DOI registration errors during upload do not stop the upload process. However the DOI creation may
fail due to various reasons like network outage or invalidity of the metadata.

## Configuration

Configuration params are defined in config.xml in this directory. Here the URL of the DOI registrar and the endpoints
for the API can be defined. 

### Credentials
For extra safety the credentials for the Registrar Service to be used have to be stored
in a resource named '/db/system/security/doi-secret.xml'. This file needs to be created
by hand. Otherwise authentication with Registrar will fail.

Structure of that file needs to be:

```
<secret>
    <user>[John Doe]</user>
    <password>[secret]</password>
</secret>
```



