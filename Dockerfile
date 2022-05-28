FROM fedora:36

ENV DOCKER_HOST=unix:///var/run/docker.sock

COPY --from=docker:dind /usr/local/bin/docker /usr/local/bin/

RUN dnf install zsh git unzip openssl bind-utils net-tools iputils iproute python3-pip jq rsync nano dnf-plugins-core htop -y \
  && dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo \
  && dnf install packer terraform -y \
  && dnf clean all

RUN curl -L "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/kubectl

RUN curl -L https://kind.sigs.k8s.io/dl/v0.14.0/kind-linux-amd64 -o /usr/local/bin/kind \
  && chmod +x /usr/local/bin/kind

RUN mkdir /tmp/k9s \
  && curl -L https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_x86_64.tar.gz -o /tmp/k9s/k9s.tar.gz \
  && tar xvf /tmp/k9s/k9s.tar.gz -C /tmp/k9s \
  && mv /tmp/k9s/k9s /usr/local/bin \
  && rm -rf /tmp/k9s \
  && chmod +x /usr/local/bin/k9s

WORKDIR /root

ENTRYPOINT /usr/bin/zsh
