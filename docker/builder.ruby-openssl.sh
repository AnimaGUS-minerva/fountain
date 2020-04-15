#!/bin/sh

cd $(dirname $0)/..
docker build -t mcr314/minerva_ruby_openssl:v202004 -f docker/Dockerfile.ruby-openssl .

