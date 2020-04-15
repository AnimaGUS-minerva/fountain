#!/bin/sh

set -e
cd $(dirname $0)/..
docker build -t mcr314/brski_fountain_builder:v202004 -f docker/Dockerfile.builder.x86_64 .
docker push mcr314/brski_fountain_builder:v202004
