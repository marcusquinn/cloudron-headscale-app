FROM cloudron/base:5.1.0@sha256:1c0666c9abe9e2090d33686826d4e97769b799124573118d41e0d7485135748e

LABEL org.opencontainers.image.source="https://github.com/marcusquinn/cloudron-headscale-app"

ARG HEADSCALE_VERSION=0.29.4
ARG HEADSCALE_SHA256=212ed0a884c0d3541e094c4bebbe94397df6f4e01bd3d7f059c520cb55e0d757

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl gosu && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /app/code/bin \
    && curl --fail --location --retry 3 --output /app/code/bin/headscale "https://github.com/juanfont/headscale/releases/download/v${HEADSCALE_VERSION}/headscale_${HEADSCALE_VERSION}_linux_amd64" \
    && printf '%s  %s\n' "${HEADSCALE_SHA256}" /app/code/bin/headscale | sha256sum --check --strict \
    && chmod 0755 /app/code/bin/headscale

COPY config.template.yaml start.sh /app/code/
RUN chmod 0755 /app/code/start.sh
EXPOSE 8080 3479/udp
CMD ["/app/code/start.sh"]
