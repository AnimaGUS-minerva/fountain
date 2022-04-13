#!/bin/sh

set -e
cd $(dirname $0)/..
docker build -t mcr314/minerva_ruby_openssl:v202204 -f docker/ruby-openssl.Dockerfile .
docker push mcr314/minerva_ruby_openssl:v202204

