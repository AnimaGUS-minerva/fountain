#!/bin/sh

# this assumes a co-located (../reach) file, and that a RAILS_ENV=development
# instance of fountain is running from this directory (in another window).

# this code requires "startjrc", and does a non-constrained voucher request.
# it is useful if MASA is running at highway-test.example.com, but it may well
# fail anyway, and the goal is to get a fresh signed voucher-request, which does
# not depend upon the voucher being returned correctly.

# What it does is use the product IDevID located in spec/files/product/*
# to regenegate voucher requests used in tests.

here=$(pwd)
serialNumber=00-D0-E5-F2-00-07

# first copy over any new IDevID from highway test environment.
mkdir -p spec/files/product/${serialNumber}
cp -Lr ../highway/spec/files/product/${serialNumber}/. spec/files/product/${serialNumber}

rm -f ../reach/tmp/vr_${serialNumber}.pkcs

(cd ../reach && rake reach:send_unsigned_voucher_request PRODUCTID=${here}/spec/files/product/${serialNumber}  JRC=https://fountain-test.example.com:8443/ )

cp ../reach/tmp/vr_${serialNumber}.pkcs       spec/files/voucher_request-${serialNumber}.pkcs
cp ../reach/tmp/voucher_${serialNumber}.pkcs  spec/files/voucher-${serialNumber}.vch

