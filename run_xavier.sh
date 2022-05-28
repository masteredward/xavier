#!/bin/bash

docker run -d \
  --name xavier \
  --hostname xavier \
  --privileged \
  -p 2222:22 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /home/core/xavier:/root \
  -v /kind:/kind \
  --restart unless-stopped \
  xavier