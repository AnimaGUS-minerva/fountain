FROM ruby:2.6 as ruby
FROM ruby:2.6 as builder

RUN apt-get update -qq && apt-get install -y postgresql-client
RUN mkdir -p /app/fountain
WORKDIR /app/fountain
COPY Gemfile /app/fountain/Gemfile
COPY Gemfile.lock /app/fountain/Gemfile.lock
RUN mkdir -p /src/minerva
RUN mkdir -p /app/minerva
RUN cd /src/minerva && git clone -b dtls-listen-refactor git://github.com/mcr/openssl.git
RUN cd /src/minerva/openssl && ./Configure --prefix=/app/minerva linux-x86_64 && id && make install_sw
RUN cd /app/minerva && git clone -b dtls-coap-client git://github.com/mcr/ruby-openssl.git
RUN gem install rake-compiler
RUN cd /app/minerva/ruby-openssl && rake compile -- --with-openssl-dir=/app/minerva
RUN gem install bundler
RUN bundle install
COPY . /app/fountain

FROM alpine
RUN apk add bash ntop sqlite
COPY --from=builder /lib/x86_64-linux-gnu/libz.so.* /lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libyaml* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /app/minerva/lib/lib* /lib/x86_64-linux-gnu/
COPY --from=builder /app/minerva/lib/lib* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/local/lib/ /usr/local/lib
COPY --from=builder /usr/local/bin/ /usr/local/bin
COPY --from=builder /app /app

WORKDIR /app/fountain
# Add a script to be executed every time the container starts.
COPY ./docker/entrypoint.sh /usr/bin/
COPY ./docker/config/database.yml /app/fountain/config
RUN chmod +x /usr/bin/entrypoint.sh
EXPOSE 3000
EXPOSE 443

CMD ["/app/fountain/startjrc"]
