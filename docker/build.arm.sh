#!/bin/sh

cd $(dirname $0)/..
docker build -t mcr314/shg_mud_supervisor:margarita -f docker/Dockerfile.arm .

docker run -v $(pwd)/../VMs/:/backup mcr314/shg_mud_supervisor:margarita tar -c -z --exclude backup --exclude proc --exclude dev --exclude sys -f /backup/shg_mud_supervisor-$(date +%Y%m%d)-margarita.tgz /
