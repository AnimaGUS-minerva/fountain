#!/bin/sh

cd $(dirname $0)/..
docker build -t mcr314/shg_mud_builder:margarita -f docker/Dockerfile.builder.arm .
docker/extract-lockfile.sh


