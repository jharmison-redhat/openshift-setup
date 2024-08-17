-include .env

CLUSTER_NAME ?= cluster
BASE_DOMAIN ?= demo.jharmison.dev
AWS_REGION ?= us-west-2
CONTROL_PLANE_TYPE ?= m6i.2xlarge
CONTROL_PLANE_COUNT ?= 1
WORKER_TYPE ?= m6i.2xlarge
WORKER_COUNT ?= 2
ARGO_GIT_URL ?= git@github.com:jharmison-redhat/openshift-setup.git
ARGO_GIT_REVISION ?= HEAD
ARGO_APPLICATIONS ?= config oauth cert-manager
CLUSTER_VERSION ?= 4.15.22
ACME_EMAIL ?=
ACME_DISABLE_ACCOUNT_KEY_GENERATION ?=
GH_REPO := $(word 1,$(subst ., ,$(word 2,$(subst :, ,$(ARGO_GIT_URL)))))

RECOVER_INSTALL := false
CLUSTER_URL := $(CLUSTER_NAME).$(BASE_DOMAIN)
CLUSTER_DIR := clusters/$(CLUSTER_URL)
INSTALL_DIR := install/$(CLUSTER_URL)

RUNTIME ?= podman
IMAGE ?= registry.jharmison.com/library/openshift-setup:latest
CONTAINER_MAKE_ARGS :=

-include $(INSTALL_DIR)/.env

export

.PHONY: all
all: container

$(INSTALL_DIR)/openshift-install:
	mkdir -p $(@D)
	curl -sLo- https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$(CLUSTER_VERSION)/openshift-install-linux.tar.gz | tar xvzf - -C $(@D) openshift-install

$(INSTALL_DIR)/oc:
	mkdir -p $(@D)
	curl -sLo- https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$(CLUSTER_VERSION)/openshift-client-linux.tar.gz | tar xvzf - -C $(@D) oc

$(INSTALL_DIR)/id_ed25519:
	mkdir -p $(@D)
	if [ ! -e $@ ]; then ssh-keygen -t ed25519 -b 512 -f $@ -C admin@$(CLUSTER_URL) -N ''; else touch $@; fi

$(INSTALL_DIR)/argo_ed25519:
	mkdir -p $(@D)
	if [ ! -e $@ ]; then ssh-keygen -t ed25519 -b 512 -f $@ -C argocd@$(CLUSTER_URL) -N ''; else touch $@; fi

$(INSTALL_DIR)/argo.txt:
	mkdir -p $(@D)
	if [ ! -e $@ ]; then age-keygen -o $@ 2>/dev/null; else touch $@; fi

.PHONY: secrets
secrets: $(INSTALL_DIR)/argo.txt
	@hack/encrypt.sh

$(INSTALL_DIR)/bootstrap/kustomization.yaml: $(INSTALL_DIR)/argo_ed25519 $(INSTALL_DIR)/argo.txt
	@hack/gen-bootstrap.sh

.PHONY: arg
.ARG~%~$(CLUSTER_URL): arg
	@if [[ $$(cat $@ 2>&1) != '$($*)' ]]; then echo -n $($*) >$@; fi

$(INSTALL_DIR)/auth/kubeconfig: $(INSTALL_DIR)/id_ed25519 $(INSTALL_DIR)/bootstrap/kustomization.yaml $(INSTALL_DIR)/openshift-install .ARG~RECOVER_INSTALL~$(CLUSTER_URL)
	@hack/install.sh

$(INSTALL_DIR)/auth/kubeconfig-orig: $(INSTALL_DIR)/auth/kubeconfig
	@if [ -e $@ ]; then \
		touch $@; else \
		cp $< $@; fi

$(CLUSTER_DIR)/cluster.yaml: $(INSTALL_DIR)/auth/kubeconfig-orig
	@hack/cluster-yaml.sh

.PHONY: cluster-yaml
cluster-yaml:
	touch $(INSTALL_DIR)/auth/kubeconfig-orig
	$(MAKE) $(CLUSTER_DIR)/cluster.yaml

.PHONY: update-applications
update-applications: $(CLUSTER_DIR)/cluster.yaml $(wildcard $(CLUSTER_DIR)/values/*/*.yaml) $(wildcard $(CLUSTER_DIR)/values/*/*.yml)
	@hack/update-applications.sh

.PHONY: bootstrap
bootstrap: $(INSTALL_DIR)/oc update-applications
	@hack/bootstrap.sh

.PHONY: encrypt
encrypt:
	@hack/encrypt.sh

.PHONY: decrypt
decrypt:
	@hack/decrypt.sh

.PHONY: start
start:
	@hack/start.sh

.PHONY: stop
stop:
	@hack/stop.sh

.PHONY: hosted-zone-setup
hosted-zone-setup:
	@hack/hosted-zone.sh

.PHONY: image
image:
	$(RUNTIME) build . --pull=newer -t $(IMAGE)
	$(RUNTIME) push $(IMAGE)

.PHONY: container
container:
	@if [ -f /run/.containerenv ]; then $(MAKE) bootstrap; else $(RUNTIME) run --rm -it --security-opt=label=disable --privileged -v "${PWD}:/workdir" -v ~/.config:/root/.config --env-host --env HOME=/root --env EDITOR=vi --env XDG_CONFIG_HOME=/root/.config --pull=newer $(IMAGE) $(CONTAINER_MAKE_ARGS); fi

.PHONY: use-kubeconfig
use-kubeconfig:
	@KUBECONFIG=$${PWD}/$(INSTALL_DIR)/auth/kubeconfig-orig PATH=$${PWD}/$(INSTALL_DIR):"$$PATH" bash --init-file \
		<(echo 'source /etc/profile; source $$HOME/.bashrc; PS1="($(CLUSTER_URL)) $$PS1"; alias oc="oc --insecure-skip-tls-verify=true"; alias k9s="k9s --insecure-skip-tls-verify"')

.PHONY: shell
shell: $(INSTALL_DIR)/oc
	@$(RUNTIME) run --rm -it --security-opt=label=disable --privileged -v "${PWD}:/workdir" -v ~/.config:/root/.config --env-host --env HOME=/root --env EDITOR=vi --env XDG_CONFIG_HOME=/root/.config --entrypoint /bin/bash --pull=newer $(IMAGE) -c 'make use-kubeconfig'

.PHONY: destroy
destroy:
	@hack/destroy.sh

.PHONY: clean
clean: destroy
	rm -rf "${INSTALL_DIR}"
