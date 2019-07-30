#!/bin/bash

fail()
{
    echo $* 1>&2
    exit 1
}

WORKSHOP_IMAGE="quay.io/openshiftlabs/lab-openshift-pipelines-with-tekton:master"

RESOURCE_BUDGET="x-large"
LETS_ENCRYPT=${LETS_ENCRYPT:-false}

TEMPLATE_REPO=https://raw.githubusercontent.com/openshift-labs/workshop-spawner
TEMPLATE_VERSION=4.2.0
TEMPLATE_FILE=learning-portal-production.json
TEMPLATE_PATH=$TEMPLATE_REPO/$TEMPLATE_VERSION/templates/$TEMPLATE_FILE

SPAWNER_APPLICATION=${SPAWNER_APPLICATION:-lab-openshift-pipelines-with-tekton}

SPAWNER_NAMESPACE=`oc project --short 2>/dev/null`

if [ "$?" != "0" ]; then
    fail "Error: Cannot determine name of project."
    exit 1
fi

echo
echo "### Creating spawner application."
echo

oc process -f $TEMPLATE_PATH \
    --param APPLICATION_NAME="$SPAWNER_APPLICATION" \
    --param PROJECT_NAME="$SPAWNER_NAMESPACE" \
    --param RESOURCE_BUDGET="$RESOURCE_BUDGET" \
    --param HOMEROOM_LINK="$HOMEROOM_LINK" \
    --param GATEWAY_ENVVARS="$GATEWAY_ENVVARS" \
    --param TERMINAL_ENVVARS="$TERMINAL_ENVVARS" \
    --param WORKSHOP_ENVVARS="$WORKSHOP_ENVVARS" \
    --param LETS_ENCRYPT="$LETS_ENCRYPT" | oc apply -f -

if [ "$?" != "0" ]; then
    fail "Error: Failed to create deployment for spawner."
    exit 1
fi

echo
echo "### Waiting for the spawner to deploy."
echo

oc rollout status dc/"$SPAWNER_APPLICATION"

if [ "$?" != "0" ]; then
    fail "Error: Deployment of spawner failed to complete."
    exit 1
fi

echo
echo "### Install global operator definitions if not already available."
echo

if [ -d ".workshop/resources/" ]; then
    oc apply -f .workshop/resources/ --recursive
else
    echo
    echo "### No /resources/ directory found. Continuing deployment."
    echo
fi

if [ "$?" != "0" ]; then
    fail "Error: Failed to create global operator definitions."
    exit 1
fi

echo
echo "### Update spawner configuration for workshop."
echo

oc process -f .workshop/templates/clusterroles-session-rules.yaml \
     --param SPAWNER_APPLICATION="$SPAWNER_APPLICATION" \
     --param SPAWNER_NAMESPACE="$SPAWNER_NAMESPACE" | oc apply -f - && \
oc process -f .workshop/templates/clusterroles-spawner-rules.yaml \
     --param SPAWNER_APPLICATION="$SPAWNER_APPLICATION" \
     --param SPAWNER_NAMESPACE="$SPAWNER_NAMESPACE" | oc apply -f - && \
oc process -f .workshop/templates/configmap-extra-resources.yaml \
     --param SPAWNER_APPLICATION="$SPAWNER_APPLICATION" \
     --param SPAWNER_NAMESPACE="$SPAWNER_NAMESPACE" | oc apply -f -

if [ "$?" != "0" ]; then
    fail "Error: Failed to udpate spawner configuration for workshop."
    exit 1
fi

echo
echo "### Restart the spawner with new configuration."
echo

oc rollout latest dc/"$SPAWNER_APPLICATION"

if [ "$?" != "0" ]; then
    fail "Error: Failed to restart the spawner."
    exit 1
fi

oc rollout status dc/"$SPAWNER_APPLICATION"

if [ "$?" != "0" ]; then
    fail "Error: Deployment of spawner failed to complete."
    exit 1
fi

echo
echo "### Updating spawner to use image for workshop."
echo

oc tag "$WORKSHOP_IMAGE" "${SPAWNER_APPLICATION}-app:latest"

if [ "$?" != "0" ]; then
    fail "Error: Failed to update spawner to use workshop image."
    exit 1
fi

echo
echo "### Route details for the spawner are as follows."
echo

oc get route "${SPAWNER_APPLICATION}"
