FROM fedora:36

LABEL maintainer="Eduardo Silva <edu.medeiros.info@gmail.com>"

ENV DOCKER_HOST=unix:///var/run/docker.sock

# Docker Client binary
COPY --from=docker:dind /usr/local/bin/docker /usr/local/bin/

# Distro utilities
RUN dnf install zsh openssh-server passwd git unzip openssl bind-utils net-tools iputils iproute python3-pip jq rsync nano dnf-plugins-core htop procps-ng helm ansible -y \
  && dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo \
  && dnf install packer terraform -y \
  && dnf clean all

# Kubectl install
RUN curl -L "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/kubectl

# Kind install
RUN curl -L https://kind.sigs.k8s.io/dl/v0.14.0/kind-linux-amd64 -o /usr/local/bin/kind \
  && chmod +x /usr/local/bin/kind

# K9s install
RUN mkdir /tmp/k9s \
  && curl -L https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_x86_64.tar.gz -o /tmp/k9s/k9s.tar.gz \
  && tar xvf /tmp/k9s/k9s.tar.gz -C /tmp/k9s \
  && mv /tmp/k9s/k9s /usr/local/bin \
  && rm -rf /tmp/k9s \
  && chmod +x /usr/local/bin/k9s

# Docker Compose V2 plugin install
RUN mkdir -p /usr/local/lib/docker/cli-plugins \
  && curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose \
  && chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# SSH setup
RUN ssh-keygen -A && passwd -d root \
  && printf "\nPasswordAuthentication no\nPermitUserEnvironment yes\n" >> /etc/ssh/sshd_config

RUN usermod -s /usr/bin/zsh root

WORKDIR /root

EXPOSE 22

ENTRYPOINT /usr/sbin/sshd -De