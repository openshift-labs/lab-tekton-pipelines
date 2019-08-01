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

TEMPLATE_REPO=https://raw.githubusercontent.com/$SPAWNER_REPO
TEMPLATE_FILE=$SPAWNER_MODE-$SPAWNER_VARIANT.json
TEMPLATE_PATH=$TEMPLATE_REPO/$SPAWNER_VERSION/templates/$TEMPLATE_FILE

echo "### Checking spawner configuration."

if [[ "$SPAWNER_MODE" =~ ^(hosted-workshop|terminal-server)$ ]]; then
    if [ x"$CLUSTER_SUBDOMAIN" == x"" ]; then
        oc create route edge $WORKSHOP_NAME-dummy \
            --service dummy --port 8080 > /dev/null 2>&1

        if [ "$?" != "0" ]; then
            fail "Cannot create dummy route $WORKSHOP_NAME-dummy."
        fi

        DUMMY_FQDN=`oc get route/$WORKSHOP_NAME-dummy -o template --template {{.spec.host}}`

        if [ "$?" != "0" ]; then
            fail "Cannot determine host from dummy route."
        fi

        DUMMY_HOST=$WORKSHOP_NAME-dummy-$PROJECT_NAME
        CLUSTER_SUBDOMAIN=`echo $DUMMY_FQDN | sed -e "s/^$DUMMY_HOST.//"`

        if [ x"$CLUSTER_SUBDOMAIN" == x"$DUMMY_FQDN" ]; then
            CLUSTER_SUBDOMAIN=""
        fi

        oc delete route $WORKSHOP_NAME-dummy > /dev/null 2>&1

        if [ "$?" != "0" ]; then
            warn "Cannot delete dummy route."
        fi
    fi

    if [ x"$CLUSTER_SUBDOMAIN" == x"" ]; then
        read -p "CLUSTER_SUBDOMAIN: " CLUSTER_SUBDOMAIN

        CLUSTER_SUBDOMAIN=$(trim $CLUSTER_SUBDOMAIN)

        if [ x"$CLUSTER_SUBDOMAIN" == x"" ]; then
            fail "Must provide valid CLUSTER_SUBDOMAIN."
        fi
    fi
fi

echo "### Creating spawner application."

TEMPLATE_ARGS=""

if [ x"$SPAWNER_MODE" == x"learning-portal" ]; then
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param RESOURCE_BUDGET=$RESOURCE_BUDGET"
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param HOMEROOM_LINK=$HOMEROOM_LINK"
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param CONSOLE_IMAGE=$CONSOLE_IMAGE"
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param SERVER_LIMIT=$SERVER_LIMIT"
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param MAX_SESSION_AGE=$MAX_SESSION_AGE"
fi

if [ x"$SPAWNER_MODE" == x"user-workspace" ]; then
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param RESOURCE_BUDGET=$RESOURCE_BUDGET"
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param HOMEROOM_LINK=$HOMEROOM_LINK"
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param CONSOLE_IMAGE=$CONSOLE_IMAGE"
fi

if [ x"$SPAWNER_MODE" == x"hosted-workshop" ]; then
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param CLUSTER_SUBDOMAIN=$CLUSTER_SUBDOMAIN"
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param CONSOLE_IMAGE=$CONSOLE_IMAGE"
fi

if [ x"$SPAWNER_MODE" == x"terminal-server" ]; then
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param CLUSTER_SUBDOMAIN=$CLUSTER_SUBDOMAIN"
    TEMPLATE_ARGS="$TEMPLATE_ARGS --param CONSOLE_IMAGE=$CONSOLE_IMAGE"
fi

if [ x"$SPAWNER_MODE" == x"jumpbox-server" ]; then
    true
fi

oc process -f $TEMPLATE_PATH \
    --param PROJECT_NAME=$PROJECT_NAME \
    --param APPLICATION_NAME=$SPAWNER_APPLICATION \
    --param GATEWAY_ENVVARS="$GATEWAY_ENVVARS" \
    --param TERMINAL_ENVVARS="$TERMINAL_ENVVARS" \
    --param WORKSHOP_ENVVARS="$WORKSHOP_ENVVARS" \
    --param IDLE_TIMEOUT=$IDLE_TIMEOUT \
    --param JUPYTERHUB_CONFIG="$JUPYTERHUB_CONFIG" \
    --param LETS_ENCRYPT=$LETS_ENCRYPT \
    $TEMPLATE_ARGS | oc apply -f -

if [ "$?" != "0" ]; then
    fail "Failed to create deployment for spawner."
    exit 1
fi

echo "### Waiting for the spawner to deploy."

oc rollout status dc/"$SPAWNER_APPLICATION"

if [ "$?" != "0" ]; then
    fail "Deployment of spawner failed to complete."
    exit 1
fi

echo "### Install static resource definitions."

if [ -d $WORKSHOP_DIR/resources/ ]; then
    oc apply -f $WORKSHOP_DIR/resources/ --recursive

    if [ "$?" != "0" ]; then
        fail "Failed to create static resource definitions."
        exit 1
    fi
fi

echo "### Update spawner configuration for workshop."

if [ -f $WORKSHOP_DIR/templates/clusterroles-session-rules.yaml ]; then
    oc process -f $WORKSHOP_DIR/templates/clusterroles-session-rules.yaml \
        --param SPAWNER_APPLICATION="$SPAWNER_APPLICATION" \
        --param SPAWNER_NAMESPACE="$PROJECT_NAME" | oc apply -f -

    if [ "$?" != "0" ]; then
        fail "Failed to update session rules for workshop."
        exit 1
    fi
fi

if [ -f $WORKSHOP_DIR/templates/clusterroles-spawner-rules.yaml ]; then
    oc process -f $WORKSHOP_DIR/templates/clusterroles-spawner-rules.yaml \
        --param SPAWNER_APPLICATION="$SPAWNER_APPLICATION" \
        --param SPAWNER_NAMESPACE="$PROJECT_NAME" | oc apply -f -

    if [ "$?" != "0" ]; then
        fail "Failed to update spawner rules for workshop."
        exit 1
    fi
fi

if [ -f $WORKSHOP_DIR/templates/configmap-extra-resources.yaml ]; then
    oc process -f $WORKSHOP_DIR/templates/configmap-extra-resources.yaml \
        --param SPAWNER_APPLICATION="$SPAWNER_APPLICATION" \
        --param SPAWNER_NAMESPACE="$PROJECT_NAME" | oc apply -f -

    if [ "$?" != "0" ]; then
        fail "Failed to update extra resources for workshop."
        exit 1
    fi
fi

echo "### Restart the spawner with new configuration."

oc rollout latest dc/"$SPAWNER_APPLICATION"

if [ "$?" != "0" ]; then
    fail "Failed to restart the spawner."
    exit 1
fi

oc rollout status dc/"$SPAWNER_APPLICATION"

if [ "$?" != "0" ]; then
    fail "Deployment of spawner failed to complete."
    exit 1
fi

echo "### Updating spawner to use image for workshop."

oc tag "$WORKSHOP_IMAGE" "$SPAWNER_APPLICATION:latest"

if [ "$?" != "0" ]; then
    fail "Failed to update spawner to use workshop image."
    exit 1
fi

echo "### Route details for the spawner are as follows."

oc get route "${SPAWNER_APPLICATION}"
