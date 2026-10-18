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

```bash
# Interactive TUI in the current folder
docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -v "$PWD:/workspace" \
  -v pi-agent-home:/root/.pi/agent \
  ghcr.io/syakyr/pi-image

# One-off prompt
docker run --rm -i \
  -e ANTHROPIC_API_KEY \
  -v "$PWD:/workspace" \
  ghcr.io/syakyr/pi-image "Create a snake game in python"
```

Replace `ANTHROPIC_API_KEY` with whichever provider credential you use. The named
`pi-agent-home` volume persists settings, credentials and sessions between runs.

Do **not** mount the host `~/.pi/agent` unless the container should have your host
Pi configuration and credentials.

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
