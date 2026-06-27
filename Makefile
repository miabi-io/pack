# Published to the GitHub Container Registry (GHCR).
IMAGE=ghcr.io/miabi-io/pack
# Image tag tracks the pinned pack CLI version (keep in sync with PACK_VERSION).
PACK_VERSION=0.40.7
TAG=$(PACK_VERSION)
PLATFORMS=linux/amd64,linux/arm64

.PHONY: build docker docker-push smoke

# Local single-arch build, tagged with the pack version and latest.
docker:
	docker build --build-arg PACK_VERSION=$(PACK_VERSION) -t $(IMAGE):$(TAG) -t $(IMAGE):latest .

# build is an alias for docker (this image ships a downloaded binary, not source).
build: docker

# Multi-arch build + push for releases.
docker-push:
	docker buildx build --push --platform=$(PLATFORMS) \
		--build-arg PACK_VERSION=$(PACK_VERSION) \
		-t $(IMAGE):$(TAG) -t $(IMAGE):latest .

# smoke builds the sample app end-to-end over a mounted Docker socket, the same
# contract Miabi uses. Requires a working Docker daemon.
smoke: docker
	docker run --rm \
		-v $(CURDIR)/examples/node-hello:/workspace \
		-v /var/run/docker.sock:/var/run/docker.sock \
		$(IMAGE):$(TAG) \
		build miabi-pack-smoke:latest \
		--path /workspace \
		--builder paketobuildpacks/builder-jammy-base \
		--docker-host inherit --trust-builder --pull-policy if-not-present
	docker image rm miabi-pack-smoke:latest || true
