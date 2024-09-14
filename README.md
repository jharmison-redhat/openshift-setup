OpenShift Setup
===============

This repository is multi-purpose.

- It allows you to provision OpenShift clusters on AWS, including being able to
  delegate subdomains into the cluster-owning AWS account from another AWS account.
- It allows you to configure OpenShift clusters, whether they were provisioned by
  this framework or not, through OpenShift GitOps pointing to a dedicated cluster
  directory in this repository.

Prerequisites
-------------

Common dependencies to use the framework:

- A container runtime that can run container instances with
  [local bind mounts](https://docs.docker.com/engine/storage/bind-mounts/#start-a-container-with-a-bind-mount).
  Some configurations of Docker or Podman on macOS and Windows have issues with this.
- Some knowledge of using a terminal.
- This repository cloned, and your terminal in the directory.

Dependencies to install an OpenShift cluster:

- An AWS IAM user access key with a public Route53 Hosted Zone available.
  - Optionally, if you have a separate AWS IAM user (possibly in a different
    account) with a Hosted Zone you would like to provide a subdomain from, for
    consumption in the first AWS account for compute/billing purposes, this
    framework can automate this as well.
- A valid Red Hat account, capable of using an
  [OpenShift Pull Secret](https://console.redhat.com/openshift/install/pull-secret)
  to install a cluster.

Usage
-----

To start, you need the framework to know the name of the cluster you are
provisioning or managing via OpenShift GitOps. The most basic of settings
required are the `CLUSTER_NAME` and `BASE_DOMAIN` environment variables. You can
either export these in your shell, or create a file at the root of the
repository named `.env` that provides them. In your shell you would type
something like:

```sh
export CLUSTER_NAME=provision-example
export BASE_DOMAIN=sandbox1234.opentlc.com
```

In the `.env` file, you can leave off the `export` (or leave it, it doesn't
matter). In this example, the API address of your cluster (whether you have the
framework provision it or whether you're adopting it) would be
`https://api.provision-example.sandbox1234.opentlc.com:6443`.

If you're provisioning a cluster, you'll also want to provide your Red Hat
[Pull Secret](https://console.redhat.com/openshift/install/pull-secret). This is
done via, for example:

```sh
export PULL_SECRET='{"auths":{"cloud.openshift.com":{"auth":"b3Bl..."},"quay.io":{"auth":"b3Bl..."},"registry.connect.redhat.com":{"auth":"NTI4..."},"registry.redhat.io":{"auth":"NTI4"}}}'
```

Again, this can go in `.env` in the root of the repository, or simply run inside
your terminal.

Other variables you may want to export or place in `.env` include `GH_TOKEN`,
`ACME_EMAIL`, `ROOT_AWS_ACCESS_KEY` and `ROOT_AWS_SECRET_ACCESS_KEY`. You can
find them documented in [Environment Variables](#environment-variables).

If you're adopting a cluster that was provisioned elsewhere, you'll want to
download and save the installation `KUBECONFIG` file in
`install/${CLUSTER_NAME}.${BASE_DOMAIN}/auth/kubeconfig`. If you used the Red
Hat Demo Platform to provision a cluster, you may have a cluster-admin
ServiceAccount in your cluster details page. You can create a `KUBECONFIG` by
running the following:

```sh
# Replace all of these values with those from your cluster details on RHDP
export CLUSTER_NAME=cluster-28qbk
export BASE_DOMAIN=28qbk.sandbox128.opentlc.com
TOKEN=eyJh...
CA_CRT='
-----BEGIN CERTIFICATE-----
MIIDM...
-----END CERTIFICATE-----
'
```

```sh
export CLUSTER_URL=${CLUSTER_NAME}.${BASE_DOMAIN}
export INSTALL_DIR=install/${CLUSTER_URL}
export KUBECONFIG=${INSTALL_DIR}/auth/kubeconfig
mkdir -p ${INSTALL_DIR}/auth
echo "${CA_CRT}" > ${INSTALL_DIR}/ca.crt
oc login --server=https://api.${CLUSTER_URL}:6443 --token="${TOKEN}" --certificate-authority="${INSTALL_DIR}/ca.crt"
unset KUBECONFIG
```

If you need to provision a cluster, or are adopting a cluster and have the AWS
credentials that provisioned this cluster, export or place those credentials in
`install/${CLUSTER_NAME}.${BASE_DOMAIN}.env`. This will allow you to more
easily keep track of these credentials if you're managing multiple clusters. They
are useful beyond simply provisioning the cluster to, for example, query the AWS
API, configure certificates with LetsEncrypt, etc.

If you are provisioning a cluster but have not created the dot-env file, you
will be prompted for these values and the dot-env file will be created for you.

From the root of the repository, you can now run `make shell` or
`./openshift-setup.sh` (whether you have GNU Make installed or not) to drop into
a container instance with the repository mounted and all the tools necessary to
use the framework, including GNU Make to support using the targets described in
[Make Targets](#make-targets).

Environment Variables
---------------------

The following environment variables influence invocation of `openshift-setup.sh`:

- `CLUSTER_NAME` (default: `cluster`)
  - Used to template the full cluster URL and its associated directories in
    install and clusters
- `BASE_DOMAIN` (default: `demo.jharmison.dev`)
  - Used to template the full cluster URL and its associated directories in
    install and clusters
- `RUNTIME` (default: `podman`)
  - Used to determine which container runtime is used in invocation. Literally
    only tested with `podman` on Linux. Might work with `docker`.
- `IMAGE` (default: `registry.jharmison.com/library/openshift-setup:latest`)
  - The container image that is pulled and entered to provide your access to the
    tooling.

The following environment variables can be set outside the container instance,
inside the container instance, in `.env` at the root or for your specific
cluster dot-environment file inside `install/${CLUSTER_NAME}.${BASE_DOMAIN}.env`
(they affect the Makefile targets where appropriate):

- `AWS_REGION` (default: `us-west-2`)
  - Determines into which region a cluster is installed (if applicable)
- `CONTROL_PLANE_TYPE` (default: `m6i.2xlarge`)
  - Determines which AWS instance type is used to install a cluster (if applicable)
- `CONTROL_PLANE_COUNT` (default: `1`)
  - *NOTE*: This can only be one of `1` or `3`, or else `openshift-install` will
    error
  - Determines the number of AWS instances provisioned for the OpenShift control
    plane (if applicable)
- `WORKER_TYPE` (default: `m6i.2xlarge`)
  - Determines which AWS instance type is used to install cluster workers (if applicable)
- `WORKER_COUNT` (default: `2`)
  - Determines the number of worker instances added to the control plane during
    provisioning (if applicable)
- `ARGO_GIT_URL` (default: `git@github.com:jharmison-redhat/openshift-setup.git`)
  - An SSH Git Remote reference, to be used by ArgoCD for wiring up retrieving
    applications and values
- `ARGO_GIT_REVISION` (default: `HEAD`)
  - A resolvable git reference for ArgoCD to follow for applications
- `ARGO_APPLICATIONS` (default: `config oauth cert-manager`)
  - A space-delimited list of ArgoCD Applications to bootstrap whether or not
    values have been provided for them.
  - Note that cert-manager being in this list will template values and secrets
    for you in support of letting the ArgoCD application manage the
    certificates. Not having cert-manager here will not trigger this templating
    of variables, so it might be preferable to remove this from the list if
    adopting a cluster with the certificates you want.
- `GH_TOKEN` (default: *unset*)
  - The GitHub token you've created at the [Personal Access Tokens Settings
    Page](https://github.com/settings/tokens) that will allow the framework to
    configure the ArgoCD Deploy Keys. Setting this will enable automatic
    configuration of the generated SSH key for this ArgoCD instance to be able
    to pull from the `ARGO_GIT_URL` described above.
- `CLUSTER_VERSION` (default: `4.15.29`)
  - The version of OpenShift to install (if applicable). Affects the version of
    `oc` and `openshift-install` downloaded as well.
- `ACME_EMAIL` (default: *unset*)
  - The email address to register with ACME for managing certificates. Must be set
    in order to request LetsEncrypt/ZeroSSL certificates.
- `ACME_DISABLE_ACCOUNT_KEY_GENERATION` (default: `true`)
  - Set to either `true` or `false`. Only applies when templating values and
    secrets for cert-manager. Will affect the configuration of the
    `ClusterIssuer`. Setting this to `true` means that you already have an
    account registered with your `ACME_EMAIL` and that account should be used,
    instead of registering a new account. If you haven't used LetsEncrypt before,
    or are unsure if you have, you should set this to `false` for at least one
    invocation.
- `RECOVER_INSTALL` (default: `false`)
  - Set to either `true` or `false`. Will allow setup to recover from a failed
    installation, if this framework performed said failed installation (cloud
    provider timeouts are a somewhat frequent cause).

Make Targets
------------

> *TODO*
