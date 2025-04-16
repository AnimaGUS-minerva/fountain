#!/bin/sh

set -e
cd $(dirname $0)/..
docker build -t dockerhub.gatineau.credil.org/minerva/minerva_ruby_openssl:v202504 -f docker/ruby-openssl.Dockerfile .
docker push dockerhub.gatineau.credil.org/minerva/minerva_ruby_openssl:v202504

