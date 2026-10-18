FROM cloudron/base:6.0.0@sha256:9bed4c8fa880645f8e669041ee28febe941481d00e9445e3e5a5483cb541d09b

LABEL org.opencontainers.image.source="https://github.com/marcusquinn/cloudron-headscale-app"

ARG HEADSCALE_VERSION=0.29.5
ARG HEADSCALE_SHA256=e979d27fe17d924d33bb6ab7504f6338d0635989a0cfdcfbc0ceb637dbcbe980

ENV PATH="/app/code/bin:${PATH}" \
    HEADSCALE_CONFIG=/app/data/config.yaml \
    HEADSCALE_VERSION=${HEADSCALE_VERSION}

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl gosu && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /app/code/bin \
    && curl --fail --location --retry 3 --output /app/code/bin/headscale "https://github.com/juanfont/headscale/releases/download/v${HEADSCALE_VERSION}/headscale_${HEADSCALE_VERSION}_linux_amd64" \
    && printf '%s  %s\n' "${HEADSCALE_SHA256}" /app/code/bin/headscale | sha256sum --check --strict \
    && chmod 0755 /app/code/bin/headscale

COPY config.template.yaml start.sh /app/code/
RUN chmod 0755 /app/code/start.sh
EXPOSE 8080 3480/udp
CMD ["/app/code/start.sh"]
