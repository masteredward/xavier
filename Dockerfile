FROM fedora:36

ARG TERRAFORM_VERSION=1.2.2 \
  PACKER_VERSION=1.8.1 \
  KIND_VERSION=0.14.0 \
  BUILDX_VERSION=0.8.2

LABEL maintainer="Eduardo Silva <edu.medeiros.info@gmail.com>"

ENV DOCKER_HOST=unix:///var/run/docker.sock

# Docker Client binary
COPY --from=docker:dind /usr/local/bin/docker /usr/local/bin/

# Distro utilities
RUN dnf install zsh openssh-server passwd git unzip openssl bind-utils net-tools iputils iproute python3-pip jq rsync nano dnf-plugins-core htop procps-ng helm ansible -y \
  && dnf clean all

ARG TARGETPLATFORM

# Hashicorp Terraform and Packer
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=amd64; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=arm64; fi \
  && mkdir /tmp/hashicorp \
  && curl -L https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCHITECTURE}.zip -o /tmp/hashicorp/terraform.zip \
  && curl -L https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_${ARCHITECTURE}.zip -o /tmp/hashicorp/packer.zip \
  && unzip /tmp/hashicorp/packer.zip -d /tmp/hashicorp \
  && unzip /tmp/hashicorp/terraform.zip -d /tmp/hashicorp \
  && mv /tmp/hashicorp/{packer,terraform} /usr/local/bin \
  && rm -rf /tmp/hashicorp \
  && chmod +x /usr/local/bin/{packer,terraform}

# Kubectl install
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=amd64; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=arm64; fi \
  && curl -L "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCHITECTURE}/kubectl" -o /usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/kubectl

# Kind install
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=amd64; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=arm64; fi \
  && curl -L https://kind.sigs.k8s.io/dl/v${KIND_VERSION}/kind-linux-${ARCHITECTURE} -o /usr/local/bin/kind \
  && chmod +x /usr/local/bin/kind

# K9s install
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=x86_64; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=arm64; fi \
  && mkdir /tmp/k9s \
  && curl -L https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${ARCHITECTURE}.tar.gz -o /tmp/k9s/k9s.tar.gz \
  && tar xvf /tmp/k9s/k9s.tar.gz -C /tmp/k9s \
  && mv /tmp/k9s/k9s /usr/local/bin \
  && rm -rf /tmp/k9s \
  && chmod +x /usr/local/bin/k9s

# Docker Compose V2 plugin install
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=x86_64; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=aarch64; fi \
  && mkdir -p /usr/local/lib/docker/cli-plugins \
  && curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-linux-${ARCHITECTURE} -o /usr/local/lib/docker/cli-plugins/docker-compose \
  && chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Docker BuildX plugin install
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=amd64; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=arm64; fi \
  && curl -L https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-${ARCHITECTURE} -o /usr/local/lib/docker/cli-plugins/docker-buildx \
  && chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx

# SSH setup
RUN ssh-keygen -A && passwd -d root \
  && printf "\nPasswordAuthentication no\nPermitUserEnvironment yes\n" >> /etc/ssh/sshd_config

RUN usermod -s /usr/bin/zsh root

WORKDIR /root

EXPOSE 22

ENTRYPOINT /usr/sbin/sshd -De
