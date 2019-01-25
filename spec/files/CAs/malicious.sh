#!/bin/sh
# this generates a CA for a manufacturer which is simply unknown.

set -e

mkdir -p malicious
cd malicious
export cadir=`pwd`

echo PASSWORD is '"badguy"'
export pass="-pass pass:badguy"
export passin="-passin pass:badguy"

#
PATH=../draft-moskowitz-ecdsa-pki-1/scripts:$PATH export PATH
. setup1.sh

# this exactly matches the CA that is setup in highway/spec/files/cert
countryName="/DC=ca"
stateOrProvinceName="/DC=sandelman"
commonName="/CN=highway-test.example.com CA"
localityName=""
organizationName=""
DN=$countryName$stateOrProvinceName$localityName
DN=$DN$organizationName$organizationalUnitName$commonName
echo $DN
export subjectAltName=email:postmaster@intermediate.malicious.example.com
export default_crl_days=2048

echo GENERATING ROOT CERTIFICATE
. rootcert.sh
echo

. intermediate_setup.sh
export DN="/DC=ca/DC=sandelman/CN=highway-test.example intermediate CA"
echo GENERATING INTERMEDIATE CERTIFICATE
. intermediate_cert.sh
echo

exit 0

commonName=""
UserID="/UID=newdevice"
DN=$countryName$stateOrProvinceName$localityName
DN=$DN$organizationName$organizationalUnitName$commonName$UserID
echo $DN
clientemail=newdevice@malicious.example.com
echo GENERATING END ENTITY CERTIFICATE
. end-client.sh
echo

#echo PUBLIC KEY for fixture:
#openssl x509 -in certs/intermediate.cert.pem -pubkey -nocert -outform der | base64
