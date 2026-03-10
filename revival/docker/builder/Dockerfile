FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
       ca-certificates \
       make \
       gcc \
       g++ \
       libc6-dev \
       libmariadb-dev \
       libmariadb-dev-compat \
       liblua5.1-0-dev \
       bash \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY docker/builder/build-legacy-linux.sh /usr/local/bin/build-legacy-linux
RUN chmod +x /usr/local/bin/build-legacy-linux

ENTRYPOINT ["/usr/local/bin/build-legacy-linux"]
