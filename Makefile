-include .env

CLUSTER_NAME ?= cluster
BASE_DOMAIN ?= demo.jharmison.dev
AWS_REGION ?= us-west-2
CONTROL_PLANE_TYPE ?= m6i.2xlarge
CONTROL_PLANE_COUNT ?= 3
WORKER_TYPE ?= m6i.2xlarge
WORKER_COUNT ?= 3
ARGO_GIT_URL ?= git@github.com:jharmison-redhat/openshift-setup.git
ARGO_GIT_REVISION ?= HEAD
ARGO_APPLICATIONS ?= config oauth cert-manager monitoring
CLUSTER_VERSION ?= 4.19.7
ACME_EMAIL ?=
ACME_DISABLE_ACCOUNT_KEY_GENERATION ?= true
GH_REPO := $(word 1,$(subst ., ,$(word 2,$(subst :, ,$(ARGO_GIT_URL)))))

RECOVER_INSTALL ?= false
CLUSTER_URL := $(CLUSTER_NAME).$(BASE_DOMAIN)
CLUSTER_DIR := clusters/$(CLUSTER_URL)
INSTALL_DIR := install/$(CLUSTER_URL)

RUNTIME ?= podman
IMAGE ?= registry.jharmison.com/library/openshift-setup:latest
CONTAINER_MAKE_ARGS ?= bootstrap
RUNTIME_ARGS := run --rm -it --security-opt=label=disable --privileged -v "$${PWD}:/workdir" -v ~/.config:/root/.config $(subst .env,--env-file .env,$(wildcard .env)) $(subst $(INSTALL_DIR).env,--env-file $(INSTALL_DIR).env,$(wildcard $(INSTALL_DIR).env)) --env HOME=/root --env EDITOR=vi --env CLUSTER_NAME=$(CLUSTER_NAME) --env BASE_DOMAIN=$(BASE_DOMAIN) --env CLUSTER_URL=$(CLUSTER_URL) --env CLUSTER_DIR=$(CLUSTER_DIR) --env INSTALL_DIR=$(INSTALL_DIR) --env XDG_CONFIG_HOME=/root/.config --env XDG_DATA_HOME=/workdir/$(INSTALL_DIR)/.data --pull=newer

-include $(INSTALL_DIR).env

export

.PHONY: all
all: container

$(INSTALL_DIR)/openshift-install:
	mkdir -p $(@D)
	curl -sLo- https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$(CLUSTER_VERSION)/openshift-install-linux.tar.gz | tar xvzf - -C $(@D) openshift-install

$(INSTALL_DIR)/oc:
	mkdir -p $(@D)
	curl -sLo- https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$(CLUSTER_VERSION)/openshift-client-linux.tar.gz | tar xvzf - -C $(@D) oc kubectl

$(INSTALL_DIR)/kubectl: $(INSTALL_DIR)/oc

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

.PHONY: install
install: $(INSTALL_DIR)/auth/kubeconfig-orig

$(CLUSTER_DIR)/cluster.yaml: $(INSTALL_DIR)/auth/kubeconfig-orig
	@hack/cluster-yaml.sh

.PHONY: cluster-yaml
cluster-yaml:
	@if [ -e $(INSTALL_DIR)/auth/kubeconfig-orig ]; then touch $(INSTALL_DIR)/auth/kubeconfig-orig; fi
	@$(MAKE) $(CLUSTER_DIR)/cluster.yaml

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

.PHONY: approve-csrs
approve-csrs:
	@hack/approve-csrs.sh

.PHONY: hosted-zone-setup
hosted-zone-setup:
	@hack/hosted-zone.sh

.PHONY: destroy
destroy:
	@hack/destroy.sh

.PHONY: clean
clean: destroy
	rm -rf "${INSTALL_DIR}"

.PHONY: image
image:
	$(RUNTIME) build container --pull=newer -t $(IMAGE)
	$(RUNTIME) push $(IMAGE)

.PHONY: container
container:
	@if [ -f /run/.containerenv ]; then $(MAKE) $(CONTAINER_MAKE_ARGS); else $(RUNTIME) $(RUNTIME_ARGS) $(IMAGE) $(CONTAINER_MAKE_ARGS); fi

.PHONY: shell
shell: $(INSTALL_DIR)/kubectl
	@$(RUNTIME) $(RUNTIME_ARGS) --entrypoint /bin/bash $(IMAGE) -li

.PHONY: test-model
test-model:
	for n in 1 5 10 32 10 5 1; do \
		locust --headless --users $$n --processes $$n -f tests/locustfile-model-endpoint.py -t 2m; \
	done

.PHONY: test-llamastack
test-llamastack:
	for n in 1 5 10 32 10 5 1; do \
		locust --headless --users $$n --processes $$n -f tests/locustfile-llama-stack-endpoint.py -t 2m; \
	done

.PHONY: test
test: test-model test-llamastack
