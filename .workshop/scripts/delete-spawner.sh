#!/bin/bash

set -x
set -eo pipefail

JUPYTERHUB_APPLICATION=${JUPYTERHUB_APPLICATION:-lab-openshift-pipelines-with-tekton}
JUPYTERHUB_NAMESPACE=`oc project --short`

APPLICATION_LABELS="app=$JUPYTERHUB_APPLICATION-$JUPYTERHUB_NAMESPACE,spawner=learning-portal"

PROJECT_RESOURCES="services,routes,deploymentconfigs,imagestreams,secrets,configmaps,serviceaccounts,rolebindings,serviceaccounts,rolebindings,persistentvolumeclaims,pods"

oc delete "$PROJECT_RESOURCES" --selector "$APPLICATION_LABELS"

CLUSTER_RESOURCES="clusterrolebindings,clusterroles"

oc delete "$CLUSTER_RESOURCES" --selector "$APPLICATION_LABELS"