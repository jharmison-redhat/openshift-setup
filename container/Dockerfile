FROM registry.fedoraproject.org/fedora:44

RUN arch=$(uname -m) && \
    if [ "$arch" = "x86_64" ]; then goarch=amd64; else goarch=arm64; fi && \
    dnf -y install \
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
    nvim \
    https://github.com/getsops/sops/releases/download/v3.13.2/sops-3.13.2-1.${arch}.rpm \
    https://github.com/derailed/k9s/releases/download/v0.51.0/k9s_linux_${goarch}.rpm \
    && dnf -y clean all \
    && python3 -m pip install --no-cache-dir locust

RUN arch=$(uname -m) && \
    if [ "$arch" = "x86_64" ]; then goarch=amd64; else goarch=arm64; fi && \
    mkdir -p /tmp/krew && cd /tmp/krew \
    && curl -fLo- "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_${goarch}.tar.gz" | tar zx \
    && "./krew-linux_${goarch}" install krew \
    && cd ~ && rm -rf /tmp/krew \
    && /root/.krew/bin/kubectl-krew install \
    browse-pvc \
    modify-secret \
    neat \
    operator \
    pexec \
    resource-capacity \
    sick-pods \
    view-secret

COPY overlay/ /
WORKDIR /workdir

RUN mkdir -p /root/.bash_completions \
    && /bin/bash -c 'openshift-setup --show-completion bash >> /root/.bashrc'

ENTRYPOINT ["make"]
CMD ["bootstrap"]
