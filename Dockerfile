FROM registry.fedoraproject.org/fedora:40

RUN dnf -y install \
      awscli2 \
      jq \
      yq \
      gh \
      curl \
      sed \
      gawk \
      git \
      gettext-envsubst \
      findutils \
      grep \
      openssh-clients \
      age \
      make \
      https://github.com/getsops/sops/releases/download/v3.9.0/sops-3.9.0-1.x86_64.rpm \
 && dnf -y clean all

WORKDIR /workdir

ENTRYPOINT ["make"]
CMD []
