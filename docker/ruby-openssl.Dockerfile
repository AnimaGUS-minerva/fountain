FROM ruby:2.6.6 as builder

RUN apt-get update -qq && apt-get install -y postgresql-client libgmp10-dev libgmp10 sash busybox dnsutils apt-utils zip dnsutils && \
    apt-get remove -y git libssl-dev &&  \
    apt-get install -y git

# build custom openssl with ruby-openssl patches

RUN gem install bundler --source=http://rubygems.org

# remove directory with broken opensslconf.h,
# build in /src, as we do not need openssl once installed
RUN rm -rf /usr/include/x86_64-linux-gnu/openssl && \
    mkdir -p /src/minerva && \
    cd /src/minerva && \
    git clone -b dtls-listen-refactor-1.1.1k git://github.com/mcr/openssl.git && \
    cd /src/minerva/openssl && \
    ./Configure --prefix=/src/openssl no-idea no-mdc2 no-rc5 no-zlib no-ssl3 no-tests no-shared linux-x86_64 && \
    id && make

RUN cd /src/minerva/openssl && make install_sw

RUN ls -l /src/openssl/lib

RUN mkdir -p /app/minerva && cd /app/minerva && \
    gem install rake-compiler --source=http://rubygems.org

RUN mkdir -p /app/minerva && cd /app/minerva && \
    git clone --single-branch --branch binary_http_multipart https://github.com/AnimaGUS-minerva/multipart_body.git && \
    git clone --single-branch --branch ecdsa_interface_openssl https://github.com/AnimaGUS-minerva/ruby_ecdsa.git && \
    git clone --single-branch --branch v0.8.0 https://github.com/mcr/ChariWTs.git chariwt && \
    git clone --single-branch --branch master https://github.com/AnimaGUS-minerva/david.git && \
    git clone --single-branch --branch aaaa_rr https://github.com/CIRALabs/dns-update.git

RUN cd /app/minerva && \
    git clone --single-branch --branch ies-cms-dtls-2020 https://github.com/mcr/ruby-openssl.git

RUN cd /app/minerva/ruby-openssl && rake compile -- --with-openssl-dir=/src/openssl

#RUN    git config --global http.sslVerify "false" && \

RUN touch /app/v202204

WORKDIR /app

