# Git-integration in TEI-Publisher

## Goal

Versioning of application *data* with Git.

Ideally supporting a range of Git providers like Github and Gitlab.

## Non-Goal

Versioning of application sourcecode

## Assumptions

Data of the application is stored in a separate XAR package to make it interchangeable separately.
As this poses no restrictions for users this setup is assumed and required for git integration.

Note: it must be discussed further how to handle ODD-files as these have direct impact on data representation and
therefore might be of interest for versioning.  

## Use Case scenarios

Both scenarios below should be supported but not at the same time. Configuration should decide
for one of them.

### Git as Master

Changes from Git are written to database.

* General thoughts 
  *  store commit hash in application to be aware which current version is installed
  * error handling will be challenging, e.q.
    * users click deploy twice before we can lock the ui
    * users force push into deployment git branch while deployment is running 
* Deploy full xar 
  * use system-execute to force pull
  * build data xar with ant and deploy it into database
* Deploy only changed files 
  * xquery to parse git diff between current commit hash and latest repo version 


#### Workflow

Editors work in filesystem and push to a git repository.

An update of the application can happen in one of two ways:

a. git triggers an update for changed data automatically

b. an editor triggers an update via UI

The update might be:

a. an complete update of the XAR

b. an partial update of the changed resources

### DB as Master

#### Workflow

Editors upload texts for validation and push those via the TEI-Publisher UI. It can be assumed for now that this
will only affect a single resoure. Therefore the UI controls should be integrated in document view.

Maybe a future version could support a browsing interface for several documents but that will need further design
considerations to not get overwhelming for the user.

The final strategy is not fully decided yet but different options include:

1. always force-push
1. show conflicts - user must confirm overwrite
1. let each user write to its own branch which will get merged eventually

## Conflict handling

Merge conflicts should be avoided as far as possible. 

It would be enourmous effort to implement a decent UI for handling those conflicts. 

A possible alternative for such scenarios would be to resort to the capabilities of Github or Gitlab for that task.
