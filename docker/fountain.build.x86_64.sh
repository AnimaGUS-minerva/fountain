#!/bin/sh

cd $(dirname $0)/..
docker build -t mcr314/minerva_fountain:v202004 -f docker/fountain.Dockerfile.x86_64 .


