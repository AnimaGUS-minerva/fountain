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


