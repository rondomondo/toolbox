# cast2gif

[cast2gif](cast2gif) is a utility script wrapper used to interact with the
[ghcr.io/rondomondo/cast2gif](ghcr.io/rondomondo/cast2gif:latest) Docker image,
which in turn incorporates [agg](https://github.com/asciinema/agg)
(asciinema GIF generator).

It converts [asciinema](https://asciinema.org/) `.cast` recording files into
GIF animations. Running agg directly as a container requires manually wiring up
Docker volume mounts so the container can read your cast file and write output
back to the host.

This wrapper handles all of that automatically: it resolves absolute paths,
mounts the right directory, and derives the output filename for you, so you can
pass a single `.cast` file, multiple `.cast` files, or a directory full of
`.cast` files and get GIF files generated for all of them.

Note: calling with `--` passes everything through directly to the agg app.

---

## Quickstart

### Install from the published ghcr.io image

The [ghcr.io/rondomondo/cast2gif](ghcr.io/rondomondo/cast2gif:latest) image
understands the `install` command so you can install what you need locally
using it like so:

```bash
setopt interactivecomments

# 1. Stream the cast2gif wrapper script to disk and make it executable
docker run --rm ghcr.io/rondomondo/cast2gif:latest install > cast2gif && chmod +x cast2gif

# 2. Install it system-wide
install -m 755 cast2gif /usr/local/bin/cast2gif

# 3. Record a terminal session with asciinema
# asciinema-rec rec demo.cast

# 4. Convert it to a GIF
cast2gif demo.cast

# 5. Done -- demo.gif should now exist
file demo.gif
```

### Install and use from the github repository

```bash
setopt interactivecomments

# 1. Clone the toolbox repo
git clone https://github.com/rondomondo/toolbox.git && cd toolbox/cast2gif

# 2. Install the wrapper script
make install

# 3. Convert an example recording
cast2gif demo.cast

# 4. Done -- demo.gif should now exist
file demo.gif
```

No Docker pull needed upfront; `cast2gif` pulls `ghcr.io/rondomondo/cast2gif:latest`
automatically on first run.

---

## Installation

From the cloned repository:

### Install `cast2gif` to `/usr/local/bin`

```bash
make install
```

### Uninstall

```bash
make uninstall
```

---

## Usage

```
cast2gif                         Show help
cast2gif -h | --help             Show help only
cast2gif <input.cast>            Convert one cast file -> <input>.gif
cast2gif <input.cast> <out.gif>  Convert one cast file with explicit output name
cast2gif <directory>             Convert every .cast file in a directory
cast2gif <cast1> <cast2> ...     Convert multiple cast files
cast2gif -- [args...]            Pass args directly to agg (e.g. --help)
```

### Examples

```bash
# Single file
cast2gif demo.cast

# Explicit output name
cast2gif session.cast output/my-recording.gif

# Whole directory
cast2gif recordings/

# Multiple files
cast2gif m0.cast m1.cast m2.cast

# Pass args directly to agg (passthrough mode)
cast2gif -- --help
```

---

## Default agg options

The wrapper applies these agg options by default. Edit `AGG_OPTIONS` in the
script to tune them.

| Option          | Default | Notes                     |
|-----------------|---------|---------------------------|
| `--rows`        | 32      | Terminal height in rows   |
| `--cols`        | 110     | Terminal width in columns |
| `--font-size`   | 24      | Font size in pixels       |
| `--line-height` | 1.6     | Line height multiplier    |

See [agg.help.txt](agg.help.txt) for the full list of agg options, including
`--theme`, `--speed`, `--idle-time-limit`, `--fps-cap`, and frame selection.

---

## What's in the image

Built on `ghcr.io/asciinema/agg:latest` with:

| Category | Included |
|---|---|
| Converter | agg (asciinema GIF generator) |
| Shell | bash |
| Extras | cast2gif wrapper, install.sh |

---

## Docker targets

```bash
make docker-build              # Build image locally
make docker-ensure             # Pull from ghcr.io (or build if unavailable)
make docker-shell              # Drop into a shell in the container
make docker-release            # Build + push versioned tag and :latest
make docker-clean              # Remove local image
```

Override the tag or registry:

```bash
make docker-build AGG_IMAGE_TAG=0.0.2
make docker-push  REGISTRY=docker.io
```

---

## Requirements

- Docker (running locally)
- `bash` 4+
- `make` (for Makefile targets)
- `asciinema` (to record `.cast` files)
