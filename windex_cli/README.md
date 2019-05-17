# Windex tools

## Installation

```bash
virtualenv venv
source venv/bin/activate
pip install -r requirements.txt
```

You will also need to install the `zbar` library on your system.

## Using client CLI

client-cli allows calling the Windex API with a simple command line, e.g.:

```bash
PYTHONPATH=src python client-cli.py --host https://<HOST> --ssl-key <SSL_KEY> --ssl-cert <SSL_CERT> user put --id 1 --body '{"name": "TEST"}'
```

You can get help on client commands and subcommands as follow:

```bash
PYTHONPATH=src python client-cli.py --help
PYTHONPATH=src python client-cli.py device --help
PYTHONPATH=src python client-cli.py device get --help
```

## Generating client sources

Client sources are generated with OpenAPI generator as follow:

```bash
openapi-generator-cli generate -i swagger.yml -g python --additional-properties="packageName=client" -o src
```

## Client documentation

[Windex client API](src/README.md)


# Windex process

## Generate a key/certificate

```bash
secp384r1
# Key
openssl ecparam -name secp384r1 -genkey -noout -out key.pem
# Certificate
openssl req -x509 -sha256 -key key.pem -out cert.pem -days 365 -subj "/C=Canada/OU=Smarkaklink-<some number>"
```

## Create a new administrator (with TOFU enabled on server):

```bash
$ PYTHONPATH=src python ./client-cli.py --host https://<HOST> --ssl-key key.pem --ssl-cert cert.pem user create --name "<Your name>"
New user Audric created with ID 1
User has admin rights
```

## Windex process

```bash
# Create the device
PYTHONPATH=src python ./client-cli.py --host https://<HOST> --ssl-key key.pem --ssl-cert cert.pem device create --name TEST_DEVICE
# List devices
PYTHONPATH=src python ./client-cli.py --host https://<HOST> --ssl-key key.pem --ssl-cert cert.pem device new
# Scan QR code
PYTHONPATH=src python ./client-cli.py --host https://<HOST> --ssl-key key.pem --ssl-cert cert.pem device scan --id=1
# Authorize device
PYTHONPATH=src python ./client-cli.py --host https://<HOST> --ssl-key key.pem --ssl-cert cert.pem device enable --id=1
```
