# Lab - OpenShift Pipelines with Tekton

* [Overview](#overview)
* [Deploying the Workshop](#deploying-the-workshop)
  * [Deploying on Red Hat Product Demo System](#deploying-on-red-hat-product-demo-system)
  * [Deploying to OpenShift](#deploying-to-openshift)
* [Running the Workshop](#running-the-workshop)
* [Deleting the Workshop](#deleting-the-workshop)
* [Development](#development)

## Overview

This workshop provides an introduction to OpenShift Pipelines with Tekton.
Please check [releases](https://github.com/openshift-labs/lab-tekton-pipelines/releases)
for the latest version of the workshop and also make sure to note if a version
released has been deprecated.

| | |
--- | ---
| Audience Experience Level | Intermediate |
| Supported Number of Users | One per cluster [1] |
| Average Time to Complete | 30 minutes |

The workshop uses the HomeRoom workshop environment in the learning portal configuration.
You will need to be a cluster admin in order to deploy it.

When the URL for the workshop environment is accessed, a workshop session will be created on demand.

## Deploying the Workshop



### Deploying on Red Hat Product Demo System

The workshop is found in the catalog under the *Workshops* folder and is named *OCP4 Pipelines Workshop*.

Once the cluster is deployed, follow the directions in the next section to begin the workshop itself.


#### Deploying on RHPDS with AgnosticD

Login to the RHPDS cluster.

```bash
oc login ...
```

Clone [AgnosticD](https://github.com/redhat-cop/agnosticd):

```bash
git clone https://github.com/redhat-cop/agnosticd
```

Install dependencies such as Python headers (Python.h), on Fedora:

```bash
sudo dnf install python3-dev
```

Setup Virtual Env:

```bash
cd agnosticd/ansible
python3 -mvenv ~/virtualenv/ansible2.9-python3.6-2021-01-22
. ~/virtualenv/ansible2.9-python3.6-2021-01-22/bin/activate
 pip install -r https://raw.githubusercontent.com/redhat-cop/agnosticd/development/tools/virtualenvs/ansible2.9-python3.6-2021-01-22.txt
```

Run the playbooks:

```bash
OCP_USERNAME="opentlc-mgr"
GUID=sampleuser
WORKSHOP_PROJECT="labs"
WORKLOAD="ocp4-workload-homeroomlab-tekton-pipelines"
TARGET_HOST=localhost

ansible-playbook -c local -i ${TARGET_HOST}, configs/ocp-workloads/ocp-workload.yml \
      -e ansible_python_interpreter=python \
      -e ocp_workload=${WORKLOAD} \
      -e guid=${GUID} \
      -e project_name=${WORKSHOP_PROJECT} \
      -e ocp_username=${OCP_USERNAME} \
      -e ACTION="create" \
      --extra-vars '{"num_users": 5}'
```

Access `labs` project and click to the Homeroom route.


### Deploying to OpenShift

WARNING: Homeroom is EOL and not supported outside RHPDS.

To deploy the workshop, first clone this Git repository to your own machine. Use the command:

```
git clone --recurse-submodules --branch 1.0 https://github.com/openshift-labs/lab-tekton-pipelines.git
```

The ``--recurse-submodules`` option ensures that Git submodules are checked out. If you forget to use this option, after having clone the repository, run:

```
git submodule update --recursive --remote
```

Next create a project in OpenShift into which the workshop is to be deployed.

```
oc new-project workshops
```

From within the top level of the Git repository, now run the command below.

```
.workshop/scripts/deploy-spawner.sh
```

The name of the pod used to start the workshop will be ``lab-tekton-pipelines-spawner``.

## Running the Workshop

Access homeroom URL:

![Workshop Login](/docs/homeroom.png)

Users will enter the following information:

| Key | Value |
| --- | ----- |
| Username | userX (e.g. user1) |
| Password | ``openshift`` |

After logging in, the workshop takes a few seconds to start:

![Workshop Startup](/docs/starting-up.png)

Once the workshop begins, users are presented with a two panel interface:

![Workshop Terminal](/docs/workshop-terminal.png)

On the left are the instructions users will follow for the workshop. The workshop itself explains how to use the interface, but generally speaking users will follow the directions on the left, with navigation buttons appearing at the end of each section. Text that is highlighted with a yellow background may be clicked to have the operation automatically executed in the cluster on the right.

By default, users are presented with the terminal, which contains (among other things) an authenticated ``oc`` client.



## Deleting the Workshop

WARNING: Homeroom is EOL and not supported outside RHPDS.


To delete the spawner and any active sessions, including projects, run:

```
./.workshop/scripts/delete-spawner.sh
```

To delete the build configuration for the workshop image, run:

```
./.workshop/scripts/delete-workshop.sh
```

To delete any global resources which may have been created, run:

```
./.workshop/scripts/delete-resources.sh
```

## Development

WARNING: Homeroom is EOL and not supported outside RHPDS.


The deployment created above will use an image from ``quay.io`` for this workshop based on the ``master`` branch of the repository.

To make changes to the workshop content and test them, edit the files in the Git repository and then run:

```
./.workshop/scripts/build-workshop.sh
```

This will replace the existing image used by the active deployment.

If you are running an existing instance of the workshop, if you want to start over with a fresh project, first delete the project used for the session.

```
oc delete project $PROJECT_NAMESPACE
```

Then select "Restart Workshop" from the menu top right of the workshop environment dashboard.

When you are happy with your changes, push them back to the remote Git repository.

If you need to change the RBAC definitions, or what resources are created when a project is created, change the definitions in the ``templates`` directory. You can then re-run:

```
./.workshop/scripts/deploy-spawner.sh
```

and it will update the active definitions.

Note that if you do this, you will need to re-run:

```
./.workshop/scripts/build-workshop.sh
```

to have any local content changes be used once again as it will revert back to using the image on ``quay.io``.
