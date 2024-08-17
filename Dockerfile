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
  bind-utils \
  helm \
  bash-completion \
  procps-ng \
  ripgrep \
  httpd-tools \
  python3-pyyaml \
  https://github.com/getsops/sops/releases/download/v3.9.0/sops-3.9.0-1.x86_64.rpm \
  https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_linux_amd64.rpm \
  && dnf -y clean all

COPY .bashrc-container /root/.bashrc
WORKDIR /workdir

ENTRYPOINT ["make"]
CMD []
