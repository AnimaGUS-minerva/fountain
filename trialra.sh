#!/bin/sh

if false; then
openssl req -extensions ra -config registrar-ssl.cnf -nodes -newkey rsa:4096 \
            -keyform PEM \
            -keyout server-key.pem \
            -out server-req.csr \
            -outform PEM
fi

# openssl req -extensions ra -config registrar-ssl.cnf -x509 -in server-req.csr -key server-key.pem -out server-key.crt

openssl req -extensions ra \
        -config registrar-ssl.cnf \
        -x509 \
        -days 1024 \
        -set_serial 1 \
        -key db/cert/jrc_secp384r1.key \
        -out db/cert/jrc_secp384r1.crt
