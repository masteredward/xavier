#!/bin/bash

docker stop xavier
docker rm xavier

docker run -d \
  --name xavier \
  --hostname xavier \
  --privileged \
  -p 2222:22 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /storage/xavier:/root \
  -v /storage/kind:/kind \
  --restart unless-stopped \
  ghcr.io/masteredward/xavier:latest