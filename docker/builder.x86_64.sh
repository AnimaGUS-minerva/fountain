#!/bin/sh

cd $(dirname $0)/..
docker build -t mcr314/brski_fountain_builder:ietf104 -f docker/Dockerfile.builder.x86_64 .

