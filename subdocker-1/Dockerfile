# subdocker-1: Debian with curl.
FROM debian:trixie-20260918-slim@sha256:a99cfc517144bc59b1978475ec53b46ecabec7e43635402ee5b77cc54cd1b20a

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
