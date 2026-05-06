# Ordering of Containers

## ruby-openssl.builder.sh

This creates a container based upon Debian Bookworm, with Ruby 3.3.8.
Within this, openssl 1.1.1t, patched to do DTLS sensibly, along with ruby-openssl that
includes ECIES, some OID patches.
The result is a container that has ruby, ruby-openssl, all in /app/minerva

## minerva.builder.x86_64.sh

This takes the ruby-openssl image from the above, and to it, builds all of the extensions that have native code.  This is done so that libraries and compilers do not need to
be present on target systems/containers.

This step needs to be run again whenever there are CVE/buildbot changes that require updates.   Nokogiri, I'm looking at you.

## fountain_gemlocker.x86_64

This uses the above image to operate the bundle update process.
The results in a new docker/Gemfile.lock which should be checked in.

## fountain.build.x86_64.sh

This produces a final fountain docker image which has all of the production code.

