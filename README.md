Lab - OpenShift Pipelines with Tekton
====================

This workshop provides an introduction to OpenShift Pipelines with Tekton.

The workshop uses the HomeRoom workshop environment in the learning portal configuration. You will need to be a cluster admin in order to deploy it.

When the URL for the workshop environment is accessed, a workshop session will be created on demand. This will include a project for the session, into which the Kafka operator will have been pre-installed.

Deploying the Workshop
----------------------

To deploy the workshop, first clone this Git repository to your own machine.

Next create a project in OpenShift into which the workshop is to be deployed.

```
oc new-project workshops
```

From within the top level of the Git repository, now run:

```
./.workshop/scripts/deploy-spawner.sh
```

The name of the deployment will be ``lab-openshift-pipelines-with-tekton``.

You can determine the hostname for the URL to access the workshop by running:

```
oc get route lab-openshift-pipelines-with-tekton
```

Editing the Workshop
--------------------

The deployment created above will use a version of the workshop which has been pre-built into an image and which is hosted on ``quay.io``.

To make changes to the workshop content and test them, edit the files in the Git repository and then run:

```
./.workshop/scripts/build-workshop.sh
```

This will replace the existing image used by the active deployment.

If you are running an existing instance of the workshop, from your web browser select "Restart Workshop" from the menu top right of the workshop environment dashboard.

When you are happy with your changes, push them back to the remote Git repository. This will automatically trigger a new build of the image hosted on ``quay.io``.

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

Deleting the Workshop
---------------------

To delete the spawner and any active sessions, including projects, run:

```
./.workshop/scripts/delete-spawner.sh
```

To delete the build configuration for the workshop image, run:

```
./.workshop/scripts/delete-workshop.sh
```

To delete special resources for CRDs and cluster roles for the Kafka operator, run:

```
./.workshop/scripts/delete-resources.sh
```

Only delete these last set of resources if the Kafka operator is not being used elsewhere in the cluster. Ideally this workshop environment should only be deployed in an expendable cluster, and not one which is shared for other work.

---  REMOVE FROM HERE ---

## LAB - AsciiDoc Sample

Sample workshop content using AsciiDoc formatting for pages.

## Develop the workshop locally on your laptop

Even though the image is being built locally, and is principally designed to be run in OpenShift, you can still run it with your local container run time. In doing this you will not have access to the embedded web console, and you will need to manually login to any remote OpenShift cluster from the terminal before going through the workshop, but everything else should still work.

To build the workshop image locally using `docker` you would run:

```bash
docker build -t lab-sample-workshop .
```

To run the image, you would then use:

```bash
docker run --rm -p 10080:10080 lab-sample-workshop
```

You can then access the workshop environment using `http://localhost:10080`.

If you want to be able to do iterative changes and test them without needing to rebuild the image each time, you can run:

```bash
docker run --rm -p 10080:10080 -v `pwd`:/opt/app-root/src lab-sample-workshop
```

This will mount your local Git repository directory into the container and the local files will be used. Each time you change the content of a page, refresh the web browser to view the latest version. You will only need to stop and restart the container if you make changes to the YAML configuration files or the `config.js` file if you are using it.

If using this method of mounting your local Git repository into the container, if the steps performed in the workshop result in modifications to files under version control, make sure you don't subsequently commit those changes. Instead, you will need to make sure you rollback such changes each time you want to run through the steps in the workshop.

## Develop the workshop on OpenShift

To develop this workshop on OpenShift.

On your workshop project do:

```bash
oc new-app https://raw.githubusercontent.com/openshift-labs/workshop-dashboard/master/templates/production.json \
  --param APPLICATION_NAME=lab-sample-workshop \
  --param AUTH_USERNAME=workshop \
  --param AUTH_PASSWORD=workshop
```

This will create a deployment called `lab-sample-workshop`. Run:

```bash
oc rollout status dc/lab-sample-workshop
```

to monitor the progress of the deployment.

Now run:

```bash
oc get is -l app=lab-sample-workshop
```

You should see that an image stream has been created corresponding to the workshop image used in the deployment. By default the image stream is set up to use the workshop dashboard image base class. This image will use some dummy workshop content used when testing. We need to substitute that image with one built from our workshop content.

To do this, we are going to create a build configuration in OpenShift for a `docker` type build. The build will be created as a binary input build so we can inject the source code for the build from the local directory.

To create the binary input build configuration run:

```bash
oc new-build --name lab-sample-workshop --binary --strategy docker
```

The name used for the build needs to be the same as the image stream above.

Now trigger a build, using the files from the current directory.

```bash
oc start-build lab-sample-workshop --from-dir . --follow
```

Once the build has complete, wait for the new deployment using this image:

```bash
oc rollout status dc/lab-sample-workshop
```

Then run:

```bash
oc get route lab-sample-workshop
```

This should show the hostname to access the newly deployed workshop content from your browser. Access the workshop on that URL.

Now, every change you want to make, you will only need to trigger a new build on OpenShift:

```bash
oc start-build lab-sample-workshop --from-dir . --follow
```
