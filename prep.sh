#! /bin/bash

set -x

# ========================================
# take over env vars set by make if they dont exist substitute some default
# note the Publiser=Author (the Publiser needs to exist before you can test the actual extension)

DIR="${DIR:-mytask1}"
Name="${NAME:-test-ado-extension}"
FriendlyName="${FRIENDLYNAME:-Testing a azure devops extension pipeline}"
Description="${DESCRIPTION:-This is a test for a azure devops extension}"
Author="${AUTHOR:-JustAnotherAuthor}"
License="${LICENSE:-MIT}"
Version="${VERSION:-0.1.0}"

# ========================================
# https://learn.microsoft.com/en-us/azure/devops/extend/develop/add-build-task?toc=%2Fazure%2Fdevops%2Fmarketplace-extensibility%2Ftoc.json&view=azure-devops
TS_VERSION="4.6.3"

# ========================================
prep_azure_devops()
{
    # do we have node installed
    node -v

    # do we have npm
    npm -v

    # To have the tsc command available,
    # make sure that TypeScript is installed globally
    # with npm in your development environment.
    sudo npm install "typescript@${TS_VERSION}" -g --save-dev
    tsc -v

    sudo npm install mocha -g --save-dev

    # Node CLI for Azure DevOps
    sudo npm install -g tfx-cli
}

init_new_directory()
{
    echo node_modules > .gitignore

    # https://docs.npmjs.com/cli/v10/commands/npm-init
    npm init --yes \
        --init-license="${License}" \
        --init-author-name="${Author}" \
        --init-version="${Version}"

    npm install azure-pipelines-task-lib --save
    # npm install typed-rest-client --save

    npm install @types/node --save-dev
    npm install @types/q --save-dev

    # Install test tools. We use Mocha as the test driver in this procedure.
    npm install sync-request --save-dev
    npm install @types/mocha --save-dev

    tsc --init --target es6 # must be es6, es2022 does not work with async function
}

init_new_task()
{
# https://learn.microsoft.com/en-us/azure/devops/extend/develop/add-build-task?toc=%2Fazure%2Fdevops%2Fmarketplace-extensibility%2Ftoc.json&view=azure-devops#taskjson-components
# Property      Description
# id            A unique GUID for your task.
# name          Name with no spaces.
# friendlyName  Descriptive name (spaces allowed).
# description   Detailed description of what your task does.
# author        Short string describing the entity developing the build or release task, for example: "Microsoft Corporation."
# instanceNameFormat    How the task displays within the build/release step list.
#               You can use variable values by using $(variablename).
# groups        Describes the logical grouping of task properties in the UI.
# inputs        Inputs to be used when your build or release task runs. This task expects an input with the name samplestring.
# execution     Execution options for this task, including scripts.
# restrictions  Restrictions being applied to the task about GitHub Codespaces commands task can call, and variables task can set.
#               We recommend that you specify restriction mode for new tasks.

    if [ -f ".uuid" ]
    then
        UUID=$( cat .uuid )
    else
        UUID=$( /usr/bin/uuid -v 4 ) # https://guid.one/guid
        echo "${UUID}" >.uuid
    fi

    cat <<! |
{
    "$schema": "https://raw.githubusercontent.com/Microsoft/azure-pipelines-task-lib/master/tasks.schema.json",
    "id": "${UUID}",
    "name": "${Name}",
    "friendlyName": "${FriendlyName}",
    "description": "${Description}",
    "helpMarkDown": "${Name}",
    "category": "Utility",
    "author": "${Author}",
    "version": {
        "Major": 0,
        "Minor": 1,
        "Patch": 0
    },
    "instanceNameFormat": "${Name}",
    "inputs": [
        {
            "name": "samplestring",
            "type": "string",
            "label": "Sample String",
            "defaultValue": "a sample string",
            "required": false,
            "helpMarkDown": "A sample string"
        }
    ],
    "execution": {
        "Node": {
            "target": "index.js"
        }
    }
}
!
    jq -r . |
    tee task.json
}

init_new_ts_file()
{
    cat <<! | tee index.ts
'use strict';
import tl = require('azure-pipelines-task-lib/task');

async function run() {
    try {
        const inputString: string | undefined = tl.getInput('samplestring', true);
        if (inputString == 'bad') {
            tl.setResult(tl.TaskResult.Failed, 'Bad input was given');
            return;
        }
        console.log('Hello', inputString);
    }
    catch (err) {
        if (err instanceof Error) {
            tl.setResult(tl.TaskResult.Failed, err.message);
        }
    }
}

run();
!

}

compile_tc2js()
{
    # to compile the ts into js do:
    tsc
}

test_run()
{
    node index.js
}

make_initial_manifest()
{
    # https://learn.microsoft.com/en-us/azure/devops/extend/develop/add-build-task?toc=%2Fazure%2Fdevops%2Fmarketplace-extensibility%2Ftoc.json&view=azure-devops#files
    # Files → Path must point to our build directory
    # https://learn.microsoft.com/en-us/azure/devops/extend/develop/add-build-task?toc=%2Fazure%2Fdevops%2Fmarketplace-extensibility%2Ftoc.json&view=azure-devops#contributions    # Contributions → Properties → Name must also point to our build directory
    # Contributions.id:
    # Identifier of the contribution.
    # Must be unique within the extension.
    # Doesn't need to match the name of the build or release task.
    # Typically the build or release task name is in the ID of the contribution.

    cat <<! | jq -r . | tee vss-extension.json
{
    "manifestVersion": 1,
    "id": "${Name}",
    "name": "${Author}",
    "version": "${Version}",
    "publisher": "${Author}",
    "public": false,
    "description": "${Description}",
    "targets": [
        {
            "id": "Microsoft.VisualStudio.Services"
        }
    ],
    "categories": [
        "Azure Pipelines"
    ],
    "icons": {
        "default": "images/extension-icon.png"
    },
    "files": [
        {
            "path": "${DIR}"
        }
    ],
    "content": {
        "details": {
          "path": "overview.md"
        }
    },
    "links": {
        "home": {
            "uri": "https://www.${Author}.com/"
        },
        "getstarted": {
            "uri": "https://www.${Author}.com/"
        },
        "learn": {
            "uri": "https://www.${Author}.com/"
        },
        "support": {
            "uri": "https://www.${Author}.com/"
        },
        "repository": {
            "uri": "https://github.com/"
        },
        "issues": {
            "uri": "https://github.com/"
        }
    },
    "repository": {
      "type": "git",
      "uri": "https://github.com/"
    },
    "tags": [
      "${Author}"
    ],
    "contributions": [
        {
            "id": "custom-build-release-task",
            "type": "ms.vss-distributed-task.task",
            "targets": [
                "ms.vss-distributed-task.tasks"
            ],
            "properties": {
                "name": "${DIR}"
            }
        }
    ]
}
!
}

make_package_extension()
{
    tfx extension create \
        --manifest-globs vss-extension.json
}

make_readme()
{
    echo "# ${Name}

${FriendlyName}

## Description

${Description}

## Author

${Author}

## License

${License}

## Version

${Version}

" >overview.md

}

main()
{
    prep_azure_devops

    grep -q '*.vsix' .gitignore || {
        echo "*.vsix" >> .gitignore
    }


    mkdir -p "${DIR}"
    pushd "${DIR}"
    {
        init_new_directory

        init_new_task
        init_new_ts_file

        compile_tc2js
        test_run
    }
    popd

    make_readme

    # make sure the image exists
    mkdir -p images
    touch images/extension-icon.png

    make_initial_manifest
    make_package_extension

    # NOTE: dont use `--rev-version`, do it yourself, see below
    # An extension or integration's version must be incremented on every update.
    # When you're updating an existing extension, either update the version in the manifest or pass the --rev-version command line switch.
    # This increments the patch version number of your extension and saves the new version to your manifest.
    # You must rev both the task version and extension version for an update to occur.
    # Note: `tfx extension create --manifest-globs vss-extension.json --rev-version` only updates the extension version and not the task version.
}

main

exit

# ##[debug]Evaluating condition for step: 'testadoextension'
# ##[debug]Evaluating: SucceededNode()
# ##[debug]Evaluating SucceededNode:
# ##[debug]=> True
# ##[debug]Result: True
# Starting: testadoextension
# ==============================================================================
# Task         : Testing a azure devops extension pipeline
# Description  : This is a test for a azure devops extension.
# Version      : 0.1.0
# Author       : JustAnotherAuthor
# Help         : test-ado-extension
# ==============================================================================
# ##[debug]Agent running environment resource - Disk: available:20047.00MB out of 74244.00MB, Memory: used 23MB out of 6921MB, CPU: usage 38.77
# ##[debug]Using node path: /home/vsts/agents/3.232.3/externals/node/bin/node
# ##[debug]agent.TempDirectory=/home/vsts/work/_temp
# ##[debug]loading inputs and endpoints
# ##[debug]loading INPUT_SAMPLESTRING
# ##[debug]loading INPUT_RLPORTAL_SERVER
# ##[debug]loading INPUT_RLPORTAL_ORG
# ##[debug]loading INPUT_RLPORTAL_GROUP
# ##[debug]loading INPUT_RL_PACKAGE_URL
# ##[debug]loading INPUT_BUILD_PATH
# ##[debug]loading INPUT_MY_ARTIFACT_TO_SCAN
# ##[debug]loading INPUT_REPORT_PATH
# ##[debug]loading ENDPOINT_AUTH_SYSTEMVSSCONNECTION
# ##[debug]loading ENDPOINT_AUTH_SCHEME_SYSTEMVSSCONNECTION
# ##[debug]loading ENDPOINT_AUTH_PARAMETER_SYSTEMVSSCONNECTION_ACCESSTOKEN
# ##[debug]loading SECRET_SYSTEM_ACCESSTOKEN
# ##[debug]loading SECRET_RLPORTAL_ACCESS_TOKEN
# ##[debug]loaded 13
# ##[debug]Agent.ProxyUrl=undefined
# ##[debug]Agent.CAInfo=undefined
# ##[debug]Agent.ClientCert=undefined
# ##[debug]Agent.SkipCertValidation=undefined
# ##[debug]samplestring=a sample string
# Hello a sample string
# Finishing: testadoextension
