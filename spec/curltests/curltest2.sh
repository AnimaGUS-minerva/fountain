#!/bin/sh

curl --trace - --key ../fountain/db/cert/jrc_secp256k1.key --cert ../fountain/db/cert/jrc_secp256k1.crt --cacert db/cert/vendor_secp384r1.crt --data-binary @curlreq.json https://localhost:8179/requestvoucher
