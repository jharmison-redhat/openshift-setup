CLUSTER_NAME ?= cluster
BASE_DOMAIN ?= demo.jharmison.dev
CONTROL_PLANE_TYPE ?= m6i.2xlarge
CONTROL_PLANE_COUNT ?= 1
WORKER_TYPE ?= m6i.2xlarge
WORKER_COUNT ?= 2
ARGO_GIT_URL ?= git@github.com:jharmison-redhat/openshift-setup.git
ARGO_GIT_REVISION ?= HEAD
ARGO_APPLICATIONS ?= config oauth cert-manager
CLUSTER_VERSION := 4.15.22

CLUSTER_URL := $(CLUSTER_NAME).$(BASE_DOMAIN)
CLUSTER_DIR := clusters/$(CLUSTER_URL)
INSTALL_DIR := install/$(CLUSTER_URL)

export

.PHONY: all
all: bootstrap

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
	if [ ! -e $@ ]; then pub=$$(age-keygen -o $@ 2>&1 | awk '{print $$NF}') && sed -i '/public_keys=/a\	'"$$pub # $(CLUSTER_URL)" common-chart-secrets.sh; else touch $@; fi

$(INSTALL_DIR)/bootstrap/kustomization.yaml: $(INSTALL_DIR)/argo_ed25519 $(INSTALL_DIR)/argo.txt
	@hack/gen-bootstrap.sh

$(INSTALL_DIR)/auth/kubeconfig: $(INSTALL_DIR)/id_ed25519 $(INSTALL_DIR)/bootstrap/kustomization.yaml $(INSTALL_DIR)/openshift-install
	@hack/install.sh

$(INSTALL_DIR)/auth/kubeconfig-orig: $(INSTALL_DIR)/auth/kubeconfig
	@if [ -e $@ ]; then \
		touch $@; else \
		cp $< $@; fi

$(CLUSTER_DIR)/cluster.yaml: $(INSTALL_DIR)/auth/kubeconfig-orig
	@hack/cluster-yaml.sh

.PHONY: update-applications
update-applications: $(CLUSTER_DIR)/cluster.yaml
	@hack/update-applications.sh

.PHONY: bootstrap
bootstrap: $(INSTALL_DIR)/oc update-applications
	@hack/bootstrap.sh

.PHONY: destroy
destroy:
	@hack/destroy.sh

.PHONY: clean
clean: destroy
	rm -rf bin

.PHONY: realclean
realclean: clean
	rm -rf install
	rm -rf bootstrap/ssh-keys.yaml
