FROM registry.access.redhat.com/ubi9

# Handle prereqs
RUN INSTALL_PKGS="python3 python3-setuptools python3-pip \
        gnupg2 httpd-tools git openssh-clients" && \
    dnf -y --setopt=tsflags=nodocs update && \
    dnf -y --setopt=tsflags=nodocs install ${INSTALL_PKGS} && \
    dnf -y clean all --enablerepo='*' && \
    ln -sf /app/vars/.aws /root/.aws

COPY requirements.txt /app/requirements.txt
RUN pip3 install --upgrade --no-cache-dir pip setuptools wheel && \
    pip3 install --upgrade --no-cache-dir -r /app/requirements.txt

RUN curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz | \
    tar xvzf - -C /usr/local/bin

# Handle requirements
WORKDIR /app
COPY requirements.yml /app/requirements.yml
RUN ansible-galaxy collection install -r requirements.yml

COPY ansible.cfg /app/ansible.cfg
COPY inventory /app/inventory
COPY playbooks /app/playbooks
COPY roles /app/roles

VOLUME /app/tmp
VOLUME /app/vars

# You should bind-mount your own tmp and vars dirs for playbook persistence.

ENTRYPOINT ["ansible-playbook"]
CMD ["--help"]
