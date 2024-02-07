# mk-minimal-ado-extension

Create a valid minimal azure devops pipeline extension skeleton.

The prep.sh only runs once to create the basic skeleton files.
This repo is not meant to update any changes after that.

## Steps

1 Update the Makefile variables with values that make sense to you,
don't remove the export.
```
    export DIR          = mytask
    export AUTHOR       = JustAnotherPublisher
    export LICENSE      = MIT
    export VERSION      = 0.1.0
    export NAME         = test-ado-extension-test
    export FRIENDLYNAME = Testing a azure devops extension pipeline
    export DESCRIPTION  = This is a test for a azure devops extension.
```
2 Run make

Note that if you want to publish the extension your Publisher should exist.

When updating the version you should update both the `${DIR}/task.json` and the `vss-extension.json`.

You can use

    verify-version-sync.sh

to validate that the versions are in sync.


