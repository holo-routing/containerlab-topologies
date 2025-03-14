FROM debian:bookworm-slim AS fastclick-builder
RUN apt update && apt install -y git libmicrohttpd-dev clang make autoconf
WORKDIR /build
RUN git clone https://github.com/nrybowski/fastclick.git
WORKDIR /build/fastclick
RUN git checkout bier
RUN autoconf && ./configure --enable-ip6 --enable-bier && make -j$(nproc)

# Make sure to compile holod with the `fastclick` feature flag!
FROM ghcr.io/holo-routing/holo:latest
RUN apt update && apt install -y curl libmicrohttpd-dev tshark
COPY --from=fastclick-builder /build/fastclick/userlevel/click /bin/click
