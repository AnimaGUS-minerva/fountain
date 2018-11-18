#!/bin/sh

curl --cacert etc/server.crt --data-binary @curlreq.json https://localhost:8179/requestvoucher
