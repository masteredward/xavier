#!/bin/bash

docker build . -t masteredward/xavier -t masteredward/xavier:f36
docker push masteredward/xavier
docker push masteredward/xavier:f36
docker system prune -af