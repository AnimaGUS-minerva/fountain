#!/bin/sh

set -e
cd $(dirname $0)/..
docker build -t mcr314/minerva_fountain:v202104 -f docker/fountain.Dockerfile.x86_64 .
docker push mcr314/minerva_fountain:v202104

