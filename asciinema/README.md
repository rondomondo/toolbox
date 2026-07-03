# asciinema-rec

[asciinema-rec](asciinema-rec) is a convenience wrapper around [asciinema](https://asciinema.org/) (via [uvx](https://docs.astral.sh/uv/)) for recording terminal sessions to `.cast` files.

## Why this exists

Recording terminal sessions with raw `asciinema` requires remembering a handful of flags every time, and the output path handling is inconsistent across environments:

- Without `-i`, long pauses bloat replay files and make recordings tedious to watch.
- Without `-y`, asciinema prompts for confirmation before overwriting -- breaking scripted or CI use.
- Without `--overwrite`, re-running the same recording command silently refuses to replace the file.
- Output paths are resolved relative to the shell's working directory, which differs between interactive use and scripts.
- Playing back recordings requires a separate `uvx asciinema play` incantation that's easy to forget.

`asciinema-rec` applies sensible defaults for all of these, resolves output paths to absolute paths, creates intermediate directories automatically, and wraps both recording and playback under a single command.

It is safe to run repeatedly -- existing `.cast` files are overwritten by default.

---

## Quickstart

### Install from the repository

```bash
# 1. Clone the toolbox repo
git clone https://github.com/rondomondo/toolbox.git && cd toolbox/asciinema

# 2. Install the wrapper script
make install

# 3. Record an interactive session
asciinema-rec session.cast

# 4. Done -- session.cast is ready to replay
asciinema-rec play session.cast
```

No separate asciinema install needed; `asciinema-rec` runs it via `uvx` automatically.

---

## Requirements

- [`uv`](https://docs.astral.sh/uv/) (provides `uvx` to run asciinema without a global install)
- `bash` 4+
- `make` (for Makefile targets)

Install `uv` with:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

---

## Installation

### Install `asciinema-rec` to `/usr/local/bin`

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
asciinema-rec                                Show this help
asciinema-rec -h | --help                    Show this help
asciinema-rec <output.cast>                  Record an interactive shell session
asciinema-rec <output.cast> <cmd> [args]     Record a command with arguments
asciinema-rec <output.cast> -- <cmd> [args]  Record a command (leading -- stripped)
asciinema-rec play <file.cast> [args]        Play back a recorded session
```

### Environment variables

The recording defaults can be overridden per-invocation via environment variables:

| Variable | Default | Effect |
|---|---|---|
| `ASCIINEMA_IDLE_TIME` | `2.5` | Clamp idle gaps to N seconds -- set to `""` to disable |
| `ASCIINEMA_YES` | `true` | Answer yes to all prompts -- set to `""` to disable |
| `ASCIINEMA_OVERWRITE` | `true` | Overwrite existing output file -- set to `""` to disable |

### Debug logging

Set `DEBUG=true` or `DEBUG=1` to enable verbose logging of invocation arguments:

```bash
DEBUG=true asciinema-rec session.cast
```

### Exit codes

| Code | Meaning |
|------|---------|
| 0 | Recording or playback completed successfully |
| 1 | Missing argument, dependency not found, or output file not written |

---

## Examples

```bash
# Interactive shell recording
asciinema-rec session.cast

# Record a single command
asciinema-rec demo.cast bash -c 'ls -la'

# Record a command using -- separator
asciinema-rec demo.cast -- python3 demo.py

# Play back a recording
asciinema-rec play session.cast

# Play back at 2x speed
asciinema-rec play session.cast -s 2

# Record without idle clamping
ASCIINEMA_IDLE_TIME="" asciinema-rec session.cast

# Upload a recording to asciinema.org
uvx asciinema upload session.cast
```

---

## How it works

| File | Role |
|---|---|
| `asciinema-rec` | Wrapper script. Resolves output paths, creates intermediate directories, invokes `uvx asciinema rec` with consistent flags, and reports success or failure. |
| `Makefile` | Developer workflow: install/uninstall the wrapper. |

### What the wrapper does on each invocation

1. Checks that `uvx` is available on `PATH`; exits with an error if not.
2. Resolves the output path to an absolute path and creates any missing parent directories.
3. Builds the `asciinema rec` flag set from the active environment variables.
4. For command recordings, joins the remaining arguments and passes them via `-c`.
5. For interactive recordings, prints a reminder to type `exit` or press `Ctrl+\` to stop.
6. Confirms the output file exists after recording completes.

---

## Makefile targets

```
make help       Show all targets
make install    Install asciinema-rec to /usr/local/bin
make uninstall  Remove asciinema-rec from /usr/local/bin
make usage      Show asciinema-rec usage
```
