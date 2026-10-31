FROM cloudron/base:6.0.1@sha256:7b1e729960c3ca312d26e886917ba89483241bba0219ff292858e10d9d5768ee

LABEL org.opencontainers.image.source="https://github.com/marcusquinn/cloudron-headscale-app"

ARG HEADSCALE_VERSION=0.29.7
ARG HEADSCALE_SHA256=e827fc9b12d958bc95b081c4401dd63f8e0471d025b45b508535a920532150a8

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
