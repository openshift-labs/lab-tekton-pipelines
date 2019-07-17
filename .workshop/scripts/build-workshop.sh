#!/bin/bash

fail()
{
    echo $* 1>&2
    exit 1
}

WORKSHOP_NAME=lab-openshift-pipelines-with-tekton

JUPYTERHUB_APPLICATION=${JUPYTERHUB_APPLICATION:-lab-openshift-pipelines-with-tekton}

JUPYTERHUB_NAMESPACE=`oc project --short 2>/dev/null`

if [ "$?" != "0" ]; then
    fail "Error: Cannot determine name of project."
    exit 1
fi

echo
echo "### Checking if already have a build configuration."
echo

oc get bc "$WORKSHOP_NAME" -o name 2>/dev/null

if [ "$?" != "0" ]; then
    echo "..."

    echo
    echo "### Creating build configuration for workshop."
    echo

    oc new-build --binary --name "$WORKSHOP_NAME"

    if [ "$?" != "0" ]; then
        fail "Error: Failed to create build configuration."
        exit 1
    fi
fi

echo
echo "### Building workshop from local content."
echo

oc start-build "$WORKSHOP_NAME" --from-dir . --follow

if [ "$?" != "0" ]; then
    fail "Error: Failed to build workshop content."
    exit 1
fi

echo
echo "### Updating spawner to use image for local workshop content."
echo

oc tag "$WORKSHOP_NAME:latest" "${JUPYTERHUB_APPLICATION}-app:latest"

if [ "$?" != "0" ]; then
    fail "Error: Failed to update spawner to use image for local workshop."
    exit 1
fi