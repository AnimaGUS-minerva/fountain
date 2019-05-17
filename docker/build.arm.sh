#!/bin/sh

set -e
cd $(dirname $0)/..
docker build -t mcr314/shg_mud_supervisor:margarita32 -f docker/Dockerfile.arm .

docker run -u root -v $(pwd)/../VMs/:/backup mcr314/shg_mud_supervisor:margarita32 tar -c -z --exclude backup --exclude proc --exclude dev --exclude sys -f /backup/shg_mud_supervisor-$(date +%Y%m%d)-margarita32.tgz /
