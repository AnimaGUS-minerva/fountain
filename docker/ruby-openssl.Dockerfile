FROM ruby:3.3.8-slim-bookworm as builder

RUN apt-get update -qq && apt-get install -y postgresql-client libgmp10-dev libgmp10 sash dnsutils zip dnsutils && \
    apt-get remove -y git libssl-dev &&  \
    apt-get install -y git build-essential

# build custom openssl with ruby-openssl patches

RUN gem install bundler --source=http://rubygems.org

# remove directory with broken opensslconf.h,
# build in /src, as we do not need openssl once installed
# no-shared to get a .a file that ruby-openssl can link, which works better if
# to you also set no-dso.
RUN rm -rf /usr/include/x86_64-linux-gnu/openssl && \
    mkdir -p /src/minerva && mkdir -p /src/openssl/lib && \
    cd /src/minerva && \
    git clone -b dtls-listen-refactor-1.1.1t https://github.com/mcr/openssl.git && \
    cd /src/minerva/openssl && \
    ./Configure --prefix=/src/openssl no-idea no-mdc2 no-rc5 no-zlib no-ssl3 no-tests \
    no-shared no-dso linux-x86_64 && \
    id && make

RUN cd /src/minerva/openssl && make install_sw

RUN ls -l /src/openssl/lib

RUN mkdir -p /app/minerva && cd /app/minerva && \
    gem install rake-compiler --source=http://rubygems.org

RUN cd /app/minerva && git clone --single-branch  --branch ruby-3-cms-1.1.1t https://github.com/mcr/ruby-openssl.git

# the static libraries are referenced as: /sandel/3rd/openssl-dtls-api/lib in the hacked
# ruby-openssl configure script, so arrange for that path to exist.
RUN mkdir -p /sandel/3rd/openssl-dtls-api/lib && ln -s /src/openssl/lib/*.a /sandel/3rd/openssl-dtls-api/lib

#RUN apt-get install -y vim
RUN cd /app/minerva/ruby-openssl && rake compile -- --with-openssl-dir=/src/openssl

#RUN touch /app/v202304

#WORKDIR /app

