#!/bin/sh

curl --cacert db/cert/ownerca_secp384r1.crt -X POST -H "Accept: */*" -H "Content-Type: application/json" --data-binary @spec/files/raw_unsigned_vr-00-12-34-56-78-9A.json https://fountain-test.example.com:8443/.well-known/brski/requestvoucher


