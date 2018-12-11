#!/bin/sh
# this generates a CA for a manufacturer which is simply unknown.

set -e
cd unknown

echo PASSWORD is '"unknown"'

PATH=../ecdsa-pki-1/scripts:$PATH export PATH
. ./setup1.sh

figlet GENERATING ROOT CERTIFICATE
. rootcert.sh
echo

figlet GENERATING INTERMEDIATE CERTIFICATE
. intermediate_cert.sh
echo

commonName=
UserID="/UID=newdevice"
DN=$countryName$stateOrProvinceName$localityName
DN=$DN$organizationName$organizationalUnitName$commonName$UserID
echo $DN
clientemail=newdevice@unknown.example.com
figlet GENERATING END ENTITY CERTIFICATE
. end-client.sh
echo

echo PUBLIC KEY for fixture:
openssl x509 -in unknown/certs/intermediate.cert.pem -pubkey -nocert -outform der | base64
