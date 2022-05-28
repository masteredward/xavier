#!/bin/bash

docker run --rm -it \
  --name xavier \
  --hostname xavier \
  --privileged \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /home/core/xavier:/root \
  -v /kind:/kind \
  xavier
