# DOI - Digital Object Identifier

All files belonging to the DOI support are found under this directory
to avoid fragmenting them within the rest of the TEI-Publisher sourcecode.

Also eases an opt-out build of TEI-Publisher.

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



