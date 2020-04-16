# Docker Setup for MINERVA FOUNTAIN

All of the docker configuration and build scripts are placed in the docker/
subdirectory.   A series of shell scripts invokes the appropriate Dockerfile
and tags, and pushes the result.

The shell script and Dockerfile(s) may need to be edited to use your docker
ID if you need to update the images.  Solutions sought for parameterizing
the Dockefile and shell scripts without introducing complexity.

The scripts are to be run in the order:
1. docker/ruby-openssl.builder.sh
2. docker/minerva.builder.x86_64.sh
3. docker/fountain.build.x86_64.sh

Note that there may also be ARM versions for use on home gateways.
All images are versioned with a "v", the year, and the month.
As in "v202004"

## Base Openssl extensions

script: docker/ruby-openssl.builder.sh

The Minerva toolset includes a number of patches to openssl 1.1.1, which fix
some issues with how DTLS works.  OpenSSL 1.1.x is also necessary to have
ECDSA support, and 1.1.1 is needed for TLS 1.3 support.

In addition, the ruby-openssl module has been extended with a CMS interface,
with ECIES support, and some other minor extensions to allow arbitrary
OIDs in certificate extensions.

These things are collected together into mcr314/minerva\_ruby\_openssl image.
This is based upon a ruby 2.6.6 debian10 image.

The openssl is created by rebasing patches after each openssl release.
This script probably does not need to be updated.

## Minerva specialized Dockerimage

script: docker/minerva.builder.x86_64.sh

The above image is further specialized with installed versions of a number of
ruby libraries that require lengthy compile steps as they extensions.
This has been placed into: mcr314/minerva_builder

## Fountain and Highway images

script: docker/fountain.build.x86_64.sh

The fountain.build script uses the minerva.builder image.
The docker-ized Gemfile is used.   It contains no debug options, and it makes
no external references, as they were loaded by the previous image.
This is done because some docker/deploy environments are unable to perform
HTTPS outgoing operations without a forced MITM TLS proxy.

The resulting images are named:
* minerva_fountain
* minerva_highway

This final image needs to be updated each time the code changes, and should
not result in significant changes each time.

# Deploying docker images

The highway (MASA/Comet Server) and fountain (Registrar, MUD-Supervisor) need
a few things to be deployed properly.

The common items are
1. A database on persistent storage, and a database.yml that points to it.
2. A persistent place to store the server certificates and private keys: /app/certificates
3. Highway: a persistent place to store devices: /app/devices

Each system needs to run a series of initialization steps.
Those steps can be repeated each time, as they are non-destructive if run a second time.

There are quite a number of ways of doing this, including docker-composer,
various kubernetes things.  These proved too annoying and complex for
development purposes.
What described below is appropriate for moderate capacity uses as it uses the
rails "thin" server directly.
If a higher capacity system is needed, then treat each of these containers as
a worker, and create as many workers as required and put a presentation tier
(load balancer) in front of it to spread the load.

For some detailed analysis of what a production ready systems might look
like, please review:
1. https://datatracker.ietf.org/doc/draft-richardson-anima-masa-considerations/
2. https://datatracker.ietf.org/doc/draft-richardson-anima-registrar-considerations/

## Network and Database configuration

The MASA container needs a single TCP port available at a public IP (v4/v6) address.
This address should have a DNS name. The port number may be arbitrary, but
either 443 or 9443 are recommended.

The Registrar container needs a single TCP port, it may also be any port,
provided that a Join Proxy is deployed.  It will typically be inward facing,
and can be numbered with an IPv6 ULA, such as when used in an Autonomic
Control Plane.  This version does not support perform the GRASP ACP announcements.

The Registrar may also provide constrained voucher service using CoAPS over a
single UDP port.  The port number 5684 is recommended, but the port number
can also be announced via GRASP ACP announcement.

Both systems need a database.  It is possible to use sqlite3.  As containers
are not persistent by default, if sqlite3 is used, it is recommended that it
be located on a third persistent volume.
The recommended database is postgresql, version 10 or higher.

The postgres:11.2 stock container can be used by mounting a persistent volume
on /var/lib/postgresql. The POSTGRES super-user password can be set by using
the "POSTGRES_PASSWORD=xyz1234".  Once the database container has been
started, accounts can be set for each web container using:

    psql -h 172.17.0.2 -U postgres

use the password specified, which above is xyz1234.  Then create a user and
database for each container, and set a password.  This can be done with
CREATE USER / CREATE DATABASE, or with the createdb/createrole commands.
(createdb, psql and createrole/createuser are part of postgresql-client
package)

I use:

    docker run --mount source=staging_data,target=/var/lib/postgresql \
       --name staging_db \
       -e POSTGRES_PASSWORD=xyz1234 -d postgres:11.2

The database is then available using the name "staging_db" within the
containers below.

## MASA setup and configuration

The arrangement described below creates a single tier IDevID PKI.
A section at the end describes how to make this a three-tier CA.
The MASA signing EE is signed by the IDevID CA, but the pledge should pin the
EE certificate directly.

In this situation, the test machine is called _eeylops_.

Create two volumes: eeylops\_certs and eeylops\_devices.

Create a Dockerfile that includes:

1. config/acme.yml  [highway]
2. config/database.yml
3. config/environments/production.rb
4. public/index.html
5. turris_root [highway]

### config/acme.yml

This file configures the ACME integration for creating IDevID certificates
via the IETF RFC8555 ACME protocol.   This can be used with services like letsencrypt.org.
If this facility is not needed, then an empty file should be created.

The hash "dns\_update\_options" should be created with the following keys:

acme_server:
: The directory URL of the ACME server that will be used.  For testing, one
can safely use the staging server at: https://acme-staging-v02.api.letsencrypt.org/directory.
It will issue certificates, but they will not be against a deployed trust
anchor.  To use the production LE server, remote the "staging-"

master:
: This is the IP address of the DNS master for the zone that will be used. A
TSIG authenticated DNS Update (RFC3007, aka Dynamic Update) will be done to this server.

key_name:
: The key name that will be used for authenticating. The key type should be
prefixed with the key name.  An HMAC-SHA256 key is recommended.

secret:
: The secret value to be used.  Typically this is a random value generated
and base64 encoded using something like:

    dd if=/dev/random bs=1 count=32 | base64

or a program like "pwgen 48 1".

print_only:
: This should be set to false in production.  If set to true, then the calls
to do DNS Updates via the "nsupdate" program will be put into debug mode.


As an example:

    dns_update_options:
      acme_server: "https://acme-staging-v02.api.letsencrypt.org/directory"
      master: '198.51.100.18'
      key_name: 'hmac-sha256:keyname'
      secret:  'A7thedmnicetPJsecretIRbvaluecQ7youiRsuseWtforTgthePUDTSIG4valuef'
      print_only: false

This goes with a BIND9 configuration containing:

    key highway. {
            algorithm hmac-sha256;
            secret:  'A7thedmnicetPJsecretIRbvaluecQ7youiRsuseWtforTgthePUDTSIG4valuef';
    };

    zone "example.org" {
            type master;
            file "example.org.signed";

            key-directory "/etc/domain/example.org";
            inline-signing yes;
            auto-dnssec maintain;

            # Then, in the "zone" definition statement for "example.org",
            # place an "update-policy" statement like this one, adjusted as
            # needed for your preferred permissions:
            update-policy {
                      grant highway. subdomain r.example.org. ANY;
            };

    };

In order to specify the zone, "example.org", and the suffix "r"
[it should have been called a prefix perhaps, except that DNS names go left-to-right]
then the database system variables are used.
This is inconsistent between settings up .yml files and entering things in
the database, and a future version will unify this into the database only.

The two variables that are needed to be set are:

shg\_suffix:
: Set this to "r", to get "r.example.org"

shg\_zone:
: Set this to "example.org"

Instructions on setting these is below using h0\_shg\_zone.

Devices which register will be given names like _nXXYYZZ.r.example.org_ based
upon a ULA that contains *fdXX:YYZZ:*

### config/database.yml

This is a YAML file that sets up the connection to the database.
As an example:

    production:
      adapter: postgresql
      database: shg_comet_staging
      username: shg_comet_staging
      password: *THEPASSWORD*
      encoding: utf8
      host: postgres
      reconnect: true

This would connect to the database called _shg\_comet\_staging_ running on
the host _postgres_.
The database should already exist, but it may be empty provided that the
named user has the proper rights to create tables.  The migration process
will create the tables and populate them.

To use an sqlite3 database, located on a persistant mount at /app/database:

    production:
     adapter: sqlite3
     database: /app/database/production.sqlite3
     pool: 5
     timeout: 5000


