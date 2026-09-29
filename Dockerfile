FROM cloudron/base:6.0.0@sha256:9bed4c8fa880645f8e669041ee28febe941481d00e9445e3e5a5483cb541d09b

LABEL org.opencontainers.image.source="https://github.com/marcusquinn/cloudron-headscale-app"

ENV PATH="/app/code/bin:${PATH}" \
    HEADSCALE_CONFIG=/app/data/config.yaml

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
