FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates tzdata gosu \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/darkspace/bin

COPY docker/runner/entrypoint.sh /usr/local/bin/revival-entrypoint
RUN chmod +x /usr/local/bin/revival-entrypoint

ENTRYPOINT ["/usr/local/bin/revival-entrypoint"]
