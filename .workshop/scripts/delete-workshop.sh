#!/bin/bash

set -x
set -eo pipefail

WORKSHOP_NAME="lab-openshift-pipelines-with-tekton"
#JUPYTERHUB_APPLICATION = ${JUPYTERHUB_APPLICATION:-lab-openshift-pipelines-with-tekton}
#JUPYTERHUB_NAMESPACE = `oc project --short`

oc delete all --selector build="$WORKSHOP_NAME"