# Xavier Administrative Container Project

**Xavier** is a [Fedora Linux](https://getfedora.org/) (Currently version 36) container. It packs a lot of management tools for development and testing. It was designed for Docker-based hosts for image building and testing, Kubernetes development and testing with the [Kind](https://kind.sigs.k8s.io/) cluster provisioning tool in mind. The name of the project is a tribute to our beloved [Professor Charles Xavier](https://www.wikipedia.org/wiki/Professor_X).

The main reason I created this project was because I wanted a dev/test lab that I could build and deploy in less than **5 minutes** from scratch, always with updated packages, completely separate from my main OS and that could be virtualized on any hypervisor.

For this purpose, I'm using the Container Linux [Flatcar](https://flatcar-linux.org/). The **Flatcar** project is a fork of the original [CoreOS](https://www.wikipedia.org/wiki/Container_Linux) project, before being transformed into the [Fedora CoreOS](https://getfedora.org/coreos). Since **Flatcar** can be deployed in a couple minutes, it fits perfectly into my 5 minute goal.

If you want to use **Flatcar** as well, refer to the folder `flatcar/`. I bundled an example *Container Linux Config file* that can be customized and transpiled into a *Ignition file* using the [Config Transpiler](https://flatcar-linux.org/docs/latest/provisioning/config-transpiler/getting-started/). Also some tips to install it faster.

Xavier is built for both *amd64* and *arm64* architetures using [BuildX](https://github.com/docker/buildx) in the same tag. This means you can use Xavier on **ARM64** Development Boards like [Raspberry Pi 3/4/400](https://www.raspberrypi.org/) or [Odroid](https://www.hardkernel.com/) without any changes.

## Some of the tools available in Xavier

- Ansible
- Curl
- Docker Client
- Docker Compose V2 plugin
- Docker BuildX plugin
- Free
- Git
- Helm
- Host and Dig
- Htop
- Jq
- K9s
- Kind
- Kubectl
- Nano
- OpenSSL
- OpenSSH
- Packer
- Python3
- Rsync
- Terraform
- Tracepath
- Unzip
- ZSH shell

## How to use Xavier

The Xavier's *Entrypoint* is the **OpenSSH** service and it exposes the default SSH port 22. This container was made to run as a daemon `docker run -d`. Use the option `-p` to forward another port from the host (like the port 2222, for example) to Xavier's port 22 `-p 2222:22`. Also, creating a [SystemD](https://systemd.io/) service eliminates the need to use the `docker` command manually to deploy Xavier. Please refer to the the folder `flatcar/` for more information.

For persisting Xavier data, bind mount the `/root` folder of Xavier to a folder in the host. Using a secondary disk for this mount is recommended. This way, you can reinstall the OS without losing Xavier's data. You can refer to the `run_xavier.sh` script to test Xavier:

```bash
docker run -d \
  --name xavier \
  --hostname xavier \
  --privileged \ # Allows you to use root capabilities of the host machine
  -p 2222:22 \ # You can use another host port
  -v /var/run/docker.sock:/var/run/docker.sock \ # Allows you to use Docker from Xavier
  -v /storage/xavier:/root \ # Persistent storage for Xavier's /root
  -v /storage/kind:/kind \ # Persistant storage for Kind clusters (optional)
  --restart unless-stopped \ # Optional if you prefer to use SystemD instead.
  ghcr.io/masteredward/xavier:latest
```

To manage Xavier as a **SystemD** service, you can create the file `xavier.service` in the folder `/etc/systemd/system` then enable and start it using `systemctl enable xavier --now`. You can use this as example:

```bash
[Unit]
Description=Xavier Admin Container
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
Restart=always
ExecStartPre=-/usr/bin/docker stop xavier
ExecStartPre=-/usr/bin/docker rm xavier
ExecStartPre=/usr/bin/docker pull ghcr.io/masteredward/xavier
ExecStart=/usr/bin/docker run --rm \
  --name xavier \
  --hostname xavier \
  --privileged \
  -p 2222:22 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /storage/xavier:/root \
  -v /storage/kind:/kind \
  ghcr.io/masteredward/xavier

[Install]
WantedBy=multi-user.target
```

## How to connect to Xavier

Password login is disabled on Xavier. You have to add a SSH public key to the `authorized_keys` file inside the Xavier's `/root` folder. Just create the `.ssh/` folder and the `authorized_keys` file inside Xavier's bind mount (e.g. `/storage/xavier/.ssh/authorized_keys`) and you're good to go!

To connect, for example:

```bash
ssh root@192.168.100.100 -i ~/.ssh/id_ed25519 -p 2222
```

Also, I recommend you to generate an [Ed25519](https://ed25519.cr.yp.to/) SSH private key instead of an outdated RSA. It offers a better security, it's faster and the public key is very compact! You can generate an **Ed25519** SSH key using `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "my@email.com"`

## Docker usage guidelines (important!)

When using Docker to deploy containers on the host machine, be aware that Xavier container *is not the host machine*! You always have to look at the paths from the host perspective. For example, if you're developing an [NodeJS](https://nodejs.org) app using it's [oficial Docker image](https://hub.docker.com/_/node) and you want to bind mount the folder `~/nodeapp` on Xavier container to the NodeJS container folder `/app`. Normally, when using your computer directly, you can write a `docker-compose.yaml` like this:

```yaml
# This will not work!

version: '3.9'

services:
  nodejs:
    image: node
    ports:
    - 3000:3000
    working_dir: /app
    volumes:
    - type: bind
      source: /root/nodeapp
      target: /app
```

Since you have to inform the path *viewing from the host perspective*, you need to figure the full path of the `/root/nodeapp` in the host machine. This can be done by looking into Xavier's **SystemD** file or the `run_xavier.sh` file on the host machine. By default, I'm binding Xavier's `/root` to `/storage/xavier` on the host machine. So, viewing from the host perspective, the **REAL PATH** for my application folder is `/storage/xavier/nodeapp`. If you change the `docker-compose.yaml` to this path instead, the problem is solved:

```yaml
# This WILL work!

version: '3.9'

services:
  nodejs:
    image: node
    ports:
    - 3000:3000
    working_dir: /app
    volumes:
    - type: bind
      source: /storage/xavier/nodeapp # This is the REAL PATH!
      target: /app
```

If you're bindind Xavier's `/root` to another folder, just make the apropriate corrections and you're good to go! Happy huntin'!

## License information

Copyright 2022 Eduardo Medeiros SIlva

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at:

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
