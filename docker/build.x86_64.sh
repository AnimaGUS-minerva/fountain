#!/bin/sh

cd $(dirname $0)/..
docker build -t mcr314/brski_fountain:ietf104 -f docker/Dockerfile.x86_64 .


