# subdocker-1: Debian with curl.
FROM debian:trixie-20261005-slim@sha256:a29215f6a35e51e22adffa17f89e9d2ef06214e64a2bad10d765c46aea49f11f

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ca-certificates is needed for HTTPS.
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

# Non-root user. /data is created here so a new named volume gets this owner.
RUN groupadd --system --gid 10001 app \
    && useradd --system --uid 10001 --gid app --home-dir /nonexistent --no-create-home --shell /usr/sbin/nologin app \
    && install -d -o app -g app -m 0750 /data

COPY --chmod=0555 run-commands.sh /usr/local/bin/run-commands.sh

USER 10001:10001
WORKDIR /data

ENTRYPOINT ["/usr/local/bin/run-commands.sh"]
# Keep the container up after startup so it can be exec'd into.
CMD ["sleep", "infinity"]
