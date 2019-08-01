#!/bin/bash

SCRIPTS_DIR=`dirname $0`

echo "### Parsing command line arguments."

for i in "$@"
do
    case $i in
        --event=*)
            EVENT_NAME="${i#*=}"
            shift
            ;;
        *)
            ;;
    esac
done

. $SCRIPTS_DIR/setup-environment.sh

echo "### Delete project resources."

APPLICATION_LABELS="app=$SPAWNER_APPLICATION-$PROJECT_NAME,spawner=$SPAWNER_MODE"

PROJECT_RESOURCES="services,routes,deploymentconfigs,imagestreams,secrets,configmaps,serviceaccounts,rolebindings,serviceaccounts,rolebindings,persistentvolumeclaims,pods"

oc delete "$PROJECT_RESOURCES" --selector "$APPLICATION_LABELS"

echo "### Delete global resources."

CLUSTER_RESOURCES="clusterrolebindings,clusterroles"

oc delete "$CLUSTER_RESOURCES" --selector "$APPLICATION_LABELS"
