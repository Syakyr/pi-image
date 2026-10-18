# pi-image

Public container image for the [pi coding agent](https://github.com/earendil-works/pi)
(`@earendil-works/pi-coding-agent`), built on every push to `main`, on `v*` tags,
and on demand via GitHub Actions.

Image: `ghcr.io/syakyr/pi-image` — platforms `linux/amd64`, `linux/arm64`.

## Tags

| Tag | Meaning |
|---|---|
| `latest` | newest build from `main` (or newest `v*` release) |
| `pi-<x.y.z>` | image built with pi npm version `x.y.z` |
| `<x.y.z>` / `<x.y>` | from git tag `vx.y.z` |

The pi npm version is pinned by the `ARG PI_VERSION` line in the [Dockerfile](Dockerfile)
— that single line is the source of truth for both the build and the tags.

## Usage

The container runs pi as an unprivileged user. Pass your host UID/GID with
`PUID`/`PGID` so bind-mounted state is writable without root, mount your whole
`~/.pi` (agent config, audit registry, memory store, guard state — everything
pi keeps there), and give Linuxbrew a named volume so `brew install` persists:

```bash
docker run --rm -it \
  -e PUID=$(id -u) -e PGID=$(id -g) \
  -v ~/.pi:/home/pi/.pi \
  -v pi-brew:/home/linuxbrew \
  -v "$PWD:/workspace" \
  --add-host=host.docker.internal:host-gateway \
  ghcr.io/syakyr/pi-image

# One-off prompt
 echo "Create a snake game in python" | docker run --rm -i \
  -e PUID=$(id -u) -e PGID=$(id -g) \
  -v ~/.pi:/home/pi/.pi \
  -v pi-brew:/home/linuxbrew \
  -v "$PWD:/workspace" \
  ghcr.io/syakyr/pi-image
```

Notes:

- Credentials come from the mounted `~/.pi/agent` (auth.json / models.json), so
  no `ANTHROPIC_API_KEY` env is needed if your provider config lives there.
- `host.docker.internal` resolves to the host gateway (for a local llama-swap
  endpoint); remote model endpoints in `models.json` just need network.
- Without `PUID`/`PGID` the container still drops to uid 1000 — fine when your
  host user *is* 1000 and the mount is owned by it.
- After a UID change the entrypoint re-owns the brew volume once (one slow
  start), then skips it. A bind-mounted `~/.pi` always keeps host ownership.
- Inside the container, absolute paths baked into your config that point at the
  host home (e.g. `/home/<you>/...`) won't resolve; workspace work happens under
  `/workspace`.

### Docker Compose

The repo ships a `compose.yml` wrapping the same invocation:

```bash
# interactive TUI on the current folder (override with WORKSPACE=/some/dir)
PUID=$(id -u) PGID=$(id -g) docker compose up

# one-off prompt
PUID=$(id -u) PGID=$(id -g) docker compose run --rm pi "Create a snake game in python"
```

It mounts `~/.pi` and a persistent `pi-brew` volume, defaults `PUID`/`PGID` to
1000, and resolves `host.docker.internal` to the host gateway. `docker compose
up` builds from the local Dockerfile if the image tag is absent; set
`WORKSPACE` to choose what lands at `/workspace` (default: `./workspace`).

### Linuxbrew

The image ships Linuxbrew at `/home/linuxbrew/.linuxbrew` (on `PATH`). With the
`pi-brew` volume mounted it persists across runs — install extra CLIs on demand:

```bash
brew install fd fzf jq
```

`build-essential` is preinstalled so the occasional source build also works.

## Building locally

```bash
docker build -t pi-image .
# or with a different pi version:
docker build --build-arg PI_VERSION=1.3.0 -t pi-image .
```

## Updating pi

No manual bump needed: the `watch-pi` workflow runs every 6 hours, reads the
newest `v*` tag from [earendil-works/pi](https://github.com/earendil-works/pi),
commits a `chore: pin pi to <version>` bump to the Dockerfile, and dispatches
`build-image.yml` if that version has no image on GHCR yet (a failed build is
retried on the next tick). To pin/build a specific version immediately, run
`watch-pi` manually with `pi_version` set. `build-image.yml` can also be run
directly; its `pi_version` input overrides the Dockerfile pin for one build.

Based on the official [Plain Docker pattern](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/containerization.md#plain-docker).
