FROM mcr314/ruby261-openssl:margarita as builder

RUN apt-get install libpq-dev
COPY Gemfile Gemfile.lock /app/fountain/
RUN /usr/local/rvm/bin/rvm 2.6.1 do bundle install
COPY . /app/fountain

FROM alpine as alpinebase
RUN mkdir -p /lib64
RUN apk add bash ntop sqlite procps

FROM alpinebase
COPY --from=builder /lib64/*                        /lib64
COPY --from=builder /lib/x86_64-linux-gnu/libpthread.so.* /lib/x86_64-linux-gnu/
COPY --from=builder /lib/x86_64-linux-gnu/librt.so.* /lib/x86_64-linux-gnu/
COPY --from=builder /lib/x86_64-linux-gnu/libdl.so.* /lib/x86_64-linux-gnu/
COPY --from=builder /lib/x86_64-linux-gnu/libm.so.* /lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libgmp.so.* /lib/x86_64-linux-gnu/
COPY --from=builder /usr/local/lib/ /usr/local/lib
COPY --from=builder /usr/local/bin/ /usr/local/bin
COPY --from=builder /usr/local/rvm/ /usr/local/rvm
COPY --from=builder /etc/profile.d/ /etc/profile.d
COPY --from=builder /lib/x86_64-linux-gnu/libcrypt.so.* /lib/x86_64-linux-gnu/
COPY --from=builder /lib/x86_64-linux-gnu/libc.so.* /lib/x86_64-linux-gnu/
COPY --from=builder /lib/x86_64-linux-gnu/libz.so.* /lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libyaml* /usr/lib/x86_64-linux-gnu/
#COPY --from=builder /app/minerva/lib/lib* /lib/x86_64-linux-gnu/
#COPY --from=builder /app/minerva/lib/lib* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /app /app

WORKDIR /app/fountain
# Add a script to be executed every time the container starts.
COPY ./docker/entrypoint.sh /usr/bin/
COPY ./docker/config/database.yml /app/fountain/config
RUN chmod +x /usr/bin/entrypoint.sh
EXPOSE 3000
EXPOSE 443

CMD ["/usr/local/rvm/bin/rvm 2.6.1 do /app/fountain/startjrc"]
