#!/bin/sh

cd $(dirname $0)/../../../..
rake reach:enroll_http_pledge PRODUCTID=spec/files/product/00-D0-E5-03-00-03 JRC=https://fountain-test.sandelman.ca:8443/


