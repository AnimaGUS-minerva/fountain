FROM ruby:2.7.6-slim-bullseye as builder

RUN apt-get update -qq && apt-get install -y postgresql-client libgmp10-dev libgmp10 sash dnsutils zip dnsutils && \
    apt-get remove -y git libssl-dev &&  \
    apt-get install -y git build-essential

# build custom openssl with ruby-openssl patches

RUN gem install bundler --source=http://rubygems.org

# remove directory with broken opensslconf.h,
# build in /src, as we do not need openssl once installed
RUN rm -rf /usr/include/x86_64-linux-gnu/openssl && \
    mkdir -p /src/minerva && mkdir -p /src/openssl/lib && \
    cd /src/minerva && \
    git clone -b dtls-listen-refactor-1.1.1r https://github.com/mcr/openssl.git && \
    cd /src/minerva/openssl && \
    ./Configure --prefix=/src/openssl no-idea no-mdc2 no-rc5 no-zlib no-ssl3 no-tests no-shared no-dso linux-x86_64 && \
    id && make

RUN cd /src/minerva/openssl && make install_sw

RUN ls -l /src/openssl/lib

RUN mkdir -p /app/minerva && cd /app/minerva && \
    gem install rake-compiler --source=http://rubygems.org

RUN cd /app/minerva && git clone --single-branch --branch dtls-1.1.1r https://github.com/mcr/ruby-openssl.git

#RUN apt-get install -y vim
RUN cd /app/minerva/ruby-openssl && rake compile -- --with-openssl-dir=/src/openssl

RUN touch /app/v202211

WORKDIR /app

