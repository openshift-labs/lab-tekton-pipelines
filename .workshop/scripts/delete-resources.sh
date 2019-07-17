#!/bin/bash

set -x

# oc delete clusterrole \
#    strimzi-cluster-operator-namespaced \
#    strimzi-cluster-operator-global \
#    strimzi-kafka-broker \
#    strimzi-entity-operator \
#    strimzi-topic-operator


# oc delete crd \
#     kafkas.kafka.strimzi.io \
#     kafkaconnects.kafka.strimzi.io \
#     kafkaconnects2is.kafka.strimzi.io \
#     kafkatopics.kafka.strimzi.io \
#     kafkausers.kafka.strimzi.io \
#     kafkamirrormakers.kafka.strimzi.io