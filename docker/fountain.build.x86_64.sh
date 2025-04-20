#!/bin/sh

set -e
cd $(dirname $0)/..
docker build -t dockerhub.gatineau.credil.org/minerva/minerva_fountain:v202504 -f docker/fountain.Dockerfile.x86_64 .
docker push dockerhub.gatineau.credil.org/minerva/minerva_fountain:v202504

#docker tag rails-alpine:7.0.3 dockerhub.gatineau.credil.org/library/rails-alpine:7.0.3
#docker push dockerhub.gatineau.credil.org/library/rails-alpine:7.0.3
