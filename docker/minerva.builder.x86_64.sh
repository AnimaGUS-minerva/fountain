#!/bin/sh

set -e
cd $(dirname $0)/..
docker build -t dockerhub.gatineau.credil.org/minerva/minerva_builder:v202304 -f docker/minerva.Dockerfile.x86_64 .
docker push dockerhub.gatineau.credil.org/minerva/minerva_builder:v202304
