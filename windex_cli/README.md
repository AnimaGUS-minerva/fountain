# Windex tools


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

```bash
# Create the device
PYTHONPATH=src python ./client-cli.py --host https://<HOST> --ssl-key <SSL_KEY> --ssl-cert <SSL_CERT> device create --name TEST_DEVICE
# List devices
PYTHONPATH=src python ./client-cli.py --host https://<HOST> --ssl-key <SSL_KEY> --ssl-cert <SSL_CERT> device new
# Scan QR code
PYTHONPATH=src python ./client-cli.py --host https://<HOST> --ssl-key <SSL_KEY> --ssl-cert <SSL_CERT> device scan --id=1
# Authorize device
PYTHONPATH=src python ./client-cli.py --host https://<HOST> --ssl-key <SSL_KEY> --ssl-cert <SSL_CERT> device enable --id=1
```
