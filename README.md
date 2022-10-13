# OpenShift 4 Easy Setup

---

## Prerequisites

- A Linux, Mac or Windows computer able to run `bash` shell scripts.
- An installed and configured container runtime (`docker` or `podman`) that your user has the privilege to execute within that `bash` shell.

## Use

**NOTE**: There is a folder named `example.com` created in the `vars` subdirectory referenced throughout these snippets. You can name it whatever you like and use it to isolate your cluster provisioning locally, just ensure that calls to `run-playbook.sh` use the name of that folder instead of `example.com` when the instructions say to call `./run-playbook.sh -c example.com`.

1. Clone this repository.

    ```shell
    git clone https://github.com/jharmison-redhat/openshift-setup.git
    cd openshift-setup
    ```

1. Copy the example variables to a new variable directory

   ```shell
   mkdir vars/cluster
   cp vars/cluster.example.yml vars/example.com/cluster.yml
   ```

1. One of several options:
   1. Provision an RHPDS cluster.
      1. From the RHPDS interface, request an OpenShift 4.5 workshop and _**enable LetsEncrypt for the cluster**_.
      1. Wait for the email from RHPDS with your cluster GUID and login information.
      1. Log in to your RHPDS cluster using `kubectl` or `oc` and the credentials provided in the RHPDS email.
   1. Export your AWS account admin IAM credentials.
   1. Download and start a [CodeReady Containers](https://developers.redhat.com/products/codeready-containers/download) cluster.
1. Edit `vars/example.com/cluster.yml` to change values. The file is commented and those comments should be read, as they explain what you may be intending to do.
1. Deploy everything using your staged answers.
   1. For a provisioned cluster, the command line should be simple:

      ```shell
      ./run-playbook.sh -c example.com cluster
      ```

   1. For an RHPDS cluster, the command line should point to your default kubeconfig with your cached login from above:

      ```shell
      ./run-playbook.sh -c example.com -k ~/.kube/config cluster
      ```

   1. For a CRC cluster, the command line should point to the default kubeconfig it stages from the installer:

      ```shell
      ./run-playbook.sh -c example.com -k ~/.crc/machine/crc/kubeconfig cluster
      ```

1. If you chose to change the console URL in the vars file, access your cluster at `console.apps.{{ cluster_name }}.{{ openshift_base_domain }}` - note that the Console route is shortened from the RHPDS provided and default console route.

1. To deprovision a self-provisioned cluster, simply execute the destroy playbook with:

   ```shell
   ./run-playbook.sh -c example.com destroy
   ```

### Development workflows

`run-playbook.sh` has been developed to use the Dockerfile present to run the playbooks and roles inside a RHEL 8 UBI container image. This means you can use run-playbook.sh to package a new container image on the fly with your changes to the repository, satisfying dependencies, and then map tmp and vars in to the container. In order to enable multiple clusters being run with multiple containers, `run-playbook.sh` requires a cluster name, and your variables should be structured into folders.

```shell
usage: run-playbook.sh [-h|--help] | [-v|--verbose] [(-e |--extra=)VARS] \
  (-c |--cluster=)CLUSTER [-k |--kubeconfig=)FILE] [-f|--force] \
  [[path/to/]PLAY[.yml]] [PLAY[.yml]]...
```

You should specify `-c example.com` or `--cluster=example.com` to define a container-managed cluster with a friendly name of example.com. In this case, the container images will be tagged as `devsecops-example.com:latest` and when executed, vars will be mapped in from `vars/example.com/`, expecting to be the default name of `cluster.yml` as needed. If you have a local `~/.kube/config` that you have a cached login (for example, as `opentlc-mgr`), you should pass the path to that file with `-k ~/.kube/config` or `--kubeconfig=~/.kube/config`. `run-playbook.sh` will copy that file into the `tmp/` directory in the appropriate place for your cluster.

Because `run-playbook.sh` stages the kubeconfig in this way, the cached logins from the playbooks will not back-propagate to your local `~/.kube/config`, so follow-on execution of `oc` or `kubectl` on your host system will not respect any changes executed in the container without using the kubeconfig in `tmp/` - which you can do by exporting the `KUBECONFIG` variable with the full path of that file, which is made easy by sourcing `prep.sh`. `prep.sh` will load a cluster's tmp directory into your `$PATH` and export `KUBECONFIG` for you so you can use `oc` for that cluster version easily.

The `-f` or `--force` options are to force-overwrite a `KUBECONFIG` file from a previous run. If you reuse a cluster name across multiple deployments, you will need this variable if you don't delete the `tmp` directories (e.g. via `destroy.yml`).

You can use the cluster name command line option to define multiple clusters, each with vars in their own subfolder, and execute any playbook from the project in the container. This means you could maintain vars folders for multiple clusters that you set up on the fly and provision or destroy them independently. They will continue to maintain kubeconfig(s) in their `tmp` subdirectory, and will all map the appropriate `vars` subdirectory for the cluster name inside of the container at runtime. Container images will only be rebuilt when the cache expires or a change has been made, so you can continue to make edits and tweaks on the fly while running this workflow.

Do note that the containers run, in a `podman` environment, as your user - without relabelling or remapping them - but on a `docker` environment they are running fully privileged. This is more privilege than containers normally get in either environment. This is to ensure that the repository files are mappable and editable by the container process as it executes, without having to tinker with UIDMAP or permissions to support this.

Additionally, you can do any portion of the following the following to skip having to specify these variables or be prompted for them:

```shell
export DEVSECOPS_CLUSTER=personal                                                # The cluster name for vars directory and container image name
./run-playbook.sh cluster
#                    ^--this is just a playbook name, present in playbooks/*.yml
```

## Contributing

We welcome pull requests and issues. Please, include as much information as possible (the git commit you deployed from, censored copies of your vars files, and any relevant logs) for issues.
