#!/bin/sh

curl -k --key spec/files/cert/jrc_prime256v1.key --cert spec/files/cert/jrc_prime256v1.crt -H "Accept: */*" -H "Content-Type: application/json" --data-binary '{"admin": true}' -X PUT https://fountain-test.example.com:8443/administrators/3
curl -k --key spec/files/cert/jrc_prime256v1.key --cert spec/files/cert/jrc_prime256v1.crt https://fountain-test.example.com:8443/administrators/3 | jq ".administrator.admin"

