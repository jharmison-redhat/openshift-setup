FROM registry.fedoraproject.org/fedora:42

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
    python3-pydantic \
    python3-typer \
    python3-dotenv \
    python3-pip \
    https://github.com/getsops/sops/releases/download/v3.10.2/sops-3.10.2-1.x86_64.rpm \
    https://github.com/derailed/k9s/releases/download/v0.50.4/k9s_linux_amd64.rpm \
    && dnf -y clean all \
    && python3 -m pip install --no-cache-dir locust

RUN mkdir -p /tmp/krew && cd /tmp/krew \
    && curl -fLo- "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz" | tar zx \
    && ./krew-linux_amd64 install krew \
    && cd ~ && rm -rf /tmp/krew \
    && /root/.krew/bin/kubectl-krew install \
    edit-status \
    modify-secret \
    neat \
    operator \
    pexec \
    pvmigrate \
    resource-capacity \
    sick-pods \
    view-secret

COPY overlay/ /
WORKDIR /workdir

RUN mkdir -p /root/.bash_completions \
    && /bin/bash -c 'openshift-setup --show-completion bash >> /root/.bashrc'

ENTRYPOINT ["make"]
CMD ["bootstrap"]
