FROM alpine:3.24 AS builder

RUN apk update && apk upgrade && apk add git gcc g++ clang rustup cmake make pcre2-dev pcre2-static protoc protobuf-dev
RUN rustup-init -y
WORKDIR /build
RUN git clone -b draft-wirtgen-bgp-tls --single-branch https://github.com/nrybowski/holo.git
WORKDIR /build/holo
RUN ~/.cargo/bin/cargo build --release
WORKDIR /build
RUN git clone https://github.com/holo-routing/holo-cli.git
WORKDIR /build/holo-cli
RUN ~/.cargo/bin/cargo build --release

FROM alpine:3.24
RUN addgroup holo
RUN addgroup holoadm
RUN adduser -S -s /sbin/nologin -h /var/opt/holo/ -G holo holo
RUN mkdir -p /var/opt/holo /var/log/holo
RUN chown holo:holoadm /var/opt/holo /var/log/holo
RUN chmod 0750 /var/opt/holo /var/log/holo
RUN apk update && apk upgrade && apk add tshark iproute2

COPY --from=builder /build/holo/target/release/holod /usr/local/sbin/
COPY --from=builder /build/holo-cli/target/release/holo-cli /usr/local/sbin

ENV RUST_BACKTRACE=1
ENV RUST_LOG=holo=debug
ENTRYPOINT ["sh", "-c", "holod -c /etc/holo/holod.toml 2>> /tmp/holod.err"]
