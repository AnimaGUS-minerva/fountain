#!/bin/sh

set -e
cd $(dirname $0)/..
docker build -t mcr314/minerva_builder:v202107 -f docker/minerva.Dockerfile.x86_64 .
docker push mcr314/minerva_builder:v202107
