ARG PACK_VERSION=0.40.7

FROM alpine:3.21 AS fetch
ARG PACK_VERSION
ARG TARGETARCH
# DL3018: deliberately unpinned — Alpine repo versions move with each point
# release and pinning them just breaks builds; --no-cache pulls the current set.
# hadolint ignore=DL3018
RUN apk add --no-cache curl ca-certificates
# pack publishes per-arch linux tarballs: amd64 -> "linux", arm64 -> "linux-arm64".
RUN set -eux; \
    case "${TARGETARCH:-amd64}" in \
      amd64) asset="pack-v${PACK_VERSION}-linux.tgz" ;; \
      arm64) asset="pack-v${PACK_VERSION}-linux-arm64.tgz" ;; \
      *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/buildpacks/pack/releases/download/v${PACK_VERSION}/${asset}" -o /tmp/pack.tgz; \
    tar -xzf /tmp/pack.tgz -C /usr/local/bin pack; \
    chmod +x /usr/local/bin/pack; \
    /usr/local/bin/pack version

FROM alpine:3.21
ARG PACK_VERSION
ENV PACK_VERSION=${PACK_VERSION}
LABEL author="Jonas Kaninda" \
      org.opencontainers.image.title="miabi/pack" \
      org.opencontainers.image.description="Cloud Native Buildpacks pack CLI helper for Miabi" \
      org.opencontainers.image.version=${PACK_VERSION}

# hadolint ignore=DL3018
RUN apk add --no-cache ca-certificates
COPY --from=fetch /usr/local/bin/pack /usr/local/bin/pack

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/pack"]
