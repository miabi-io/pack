# miabi/pack

A tiny sibling helper image that ships the [Cloud Native Buildpacks](https://buildpacks.io)
`pack` CLI so [Miabi](https://github.com/miabi-io/miabi) can build an app from a
**git repository with no Dockerfile**. Miabi runs this image as a one-shot
container on the app's node — the same pattern it uses for `pg-bkup`,
`volume-bkup`, and other helpers.

The image carries only:

- the **pinned** `pack` binary at `/usr/local/bin/pack` (entrypoint),
- CA certificates.

No docker CLI (pack talks to the daemon directly over the mounted socket) and no
git (Miabi mounts an already-cloned workspace).

## Contract (how Miabi invokes it)

Miabi runs the container with two bind mounts and a `pack build` command:

| Mount | Purpose |
|-------|---------|
| `<cloned repo>` → `/workspace` | the source tree to build |
| `/var/run/docker.sock` → `/var/run/docker.sock` | the node daemon pack exports the image into |

```sh
docker run --rm \
  -v /path/to/cloned/repo:/workspace \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/miabi-io/pack:latest \
  build miabi/app-5:27 \
    --path /workspace \
    --builder paketobuildpacks/builder-jammy-base \
    --docker-host inherit \
    --trust-builder \
    --pull-policy if-not-present
```

Without `--publish`, `pack` exports the built image into the **local daemon**
(it stays on the node, exactly like a `docker build`). `pack` manages its own
layer-cache volumes keyed on the image name, so rebuild caching works
automatically across deploys.

The resulting image runs via the CNB **launcher**: it starts the `web` process
type and listens on `$PORT`. Miabi injects `PORT` and does not set a custom
command for buildpack-built images.

## ⚠️ Trust boundary (docker.sock)

This container is **root-equivalent on the node** through the mounted Docker
socket, and it builds **untrusted source**. Miabi mitigates this with a hard
build timeout, CPU/memory caps on the build container, and a per-node
concurrency guard — but operators should understand that buildpack builds run
with daemon access. A rootless/BuildKit build path is a later option.

## Versioning

The image tag tracks the pinned `pack` CLI version (`PACK_VERSION` in the
[Makefile](./Makefile) and [Dockerfile](./Dockerfile)). The default builder is
pinned by Miabi's image catalog (`build.buildpack-builder`), not baked in here,
so operators can repoint it without rebuilding this image.

## Build

```sh
make docker          # local build  -> ghcr.io/miabi-io/pack:<version> + :latest
make docker-push     # multi-arch build + push (amd64, arm64)
make smoke           # build the sample app end-to-end over a mounted socket
```

## License

Apache 2.0 — see [LICENSE](./LICENSE).
