#!/bin/bash

SCRIPTS_DIR=`dirname $0`

. $SCRIPTS_DIR/setup-environment.sh

echo "### Delete build configuation."

oc delete all --selector build="$WORKSHOP_NAME"
