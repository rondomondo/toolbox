# toolbox

A collection of small CLI utilities for terminal recording, diagram rendering, PDF sanitisation, and text cleaning — all zero-install, Docker-backed where needed.

---

## Tools

### [pdf-strip](pdf-strip/)

**`pdf-strip`** -- PDFs carry hidden metadata that survives sharing: author name, creation date, software version, edit history, GPS coordinates from embedded images. None of it is visible in the document yet all of it travels with the file. `pdf-strip` removes it all. Including the legacy `/Info` dictionary, the XMP metadata stream, and macOS extended attributes. Implemented using `pikepdf` inside Docker so there's nothing to install locally. Output is written as `<base>.stripped.pdf`; originals are never modified.

```bash
docker run --rm ghcr.io/rondomondo/pdf-strip install
```

```bash
pdf-strip report.pdf           # strip metadata -> report.stripped.pdf
pdf-strip --check report.pdf   # inspect metadata without modifying
pdf-strip ./my-docs/           # process all PDFs in a directory
```

---

### [sanitise-ascii](sanitise-ascii/)

**`sanitise-ascii`** -- sometimes copy-paste from the web, word, md files, notion etc., quietly introduces smart quotes, em-dashes, non-breaking spaces, and BOMs that break scripts, linters, and pipelines in ways that are genuinely hard to debug. `sanitise-ascii` scans source files and Markdown for every non-ASCII character, replaces the 40+ common known offenders with their ASCII equivalents, and flags anything it can't resolve so nothing is silently dropped. Safe to run repeatedly; clean files are left untouched.

```bash
sanitise-ascii --check --dir .   # dry-run: report non-ASCII
sanitise-ascii --dir .           # auto-fix in place
sanitise-ascii --check README.md # check a specific file
sanitise-ascii --fix README.md   # fix a specific file
```

---

### [asciinema](asciinema/)

**`asciinema-rec`** -- recording a terminal session for presentation, demo or distribution shouldn't require a global install or memorising flags. `asciinema-rec` wraps [asciinema](https://asciinema.org/) via `uvx` with sane defaults baked in: idle gaps clamped to 2.5s (so pauses don't explode/bloat the file), overwrite is on, output directories created automatically. Sessions are saved as `.cast` files -- a compact, timestamped JSON format that pairs naturally with `cast2gif` when you need a GIF for a README, slide or distribution.

```bash
asciinema-rec session.cast                  # interactive session -> session.cast
asciinema-rec demo.cast -- python3 demo.py  # record a single command
asciinema-rec play session.cast             # replay a previous recording
```

---

### [cast2gif](cast2gif/)

**`cast2gif`** -- `.cast` files are compact and replayable, but useless in a PR description, a README, or a slide deck. `cast2gif` converts asciinema recordings to GIF animations using [agg](https://github.com/asciinema/agg) inside Docker -- no local install, no path confusion, or messing with volume mounts. Run it with a single file, several files, or a whole directory and it produces images alongside the originals. Defaults are tuned for readability: 110 columns, 32 rows, 24pt font.

```bash
docker run --rm ghcr.io/rondomondo/cast2gif install
```

```bash
cast2gif session.cast          # -> session.gif
cast2gif recordings/           # convert every .cast in a directory
cast2gif a.cast b.cast         # convert multiple files at once
```

---

### [vhs](vhs/)

**`vhs-rec`** -- a `.tape` file is a declarative script for a terminal recording: set the font, shell, and dimensions; then type keystrokes, sleep, and hit enter. [VHS](https://github.com/charmbracelet/vhs) turns it into a GIF. `vhs-rec` runs VHS in Docker, extended with Docker-in-Docker support, multiple example font families (JetBrains Mono, Fira Code...), and also a full dev toolchain -- so you can record workflows that themselves invoke Docker, `make`, or `git` without fighting the container boundary. Output paths in the tape file are rewritten automatically.

```bash
docker run --rm ghcr.io/rondomondo/vhs-rec install
```

```bash
vhs-rec demo.tape              # -> demo.gif
vhs-rec test/                  # convert every .tape in a directory
vhs-rec -- validate demo.tape  # pass args directly to vhs (denoted with --)
```

---

### [mermaid-render](mermaid-render/)

**`mermaid-render`** -- Mermaid diagrams are great while they live in Markdown, but you can't embed a fenced code block in a slide, a Confluence page, or a Notion doc. `mermaid-render` finds every ` ```mermaid ` block in a `.md` file, renders each one to a numbered SVG, PNG, or PDF via Docker, and writes a companion Markdown file with `![diagram](...)` image references replacing the code blocks. The originals are never modified, so the source of truth stays in the `.md` file and you re-render whenever things change.

```bash
docker run --rm ghcr.io/rondomondo/mermaid-render install
```

```bash
mermaid-render diagram.md              # render all blocks -> SVG (default)
mermaid-render diagram.md -f png -s 2  # PNG at 2x scale
mermaid-render ./docs/ -f svg          # render every .md with mermaid blocks in a directory
mermaid-render -- --help               # pass args directly to mmdc
```

---

### [filetree](filetree/)

**`filetree`** -- documenting a project's layout means either writing the tree by hand or running `tree` and hoping it's installed. `filetree` generates file tree visualisations using only `find`, `awk`, and bash, so no dependencies, works anywhere. Output in unicode, ASCII, or compact style; `.git`, `node_modules`, `__pycache__`, and the usual noise are skipped by default. Paste the output straight into a README etc.

```bash
filetree                              # tree of current directory
filetree src/                         # tree of a specific directory
filetree --style ascii .              # ASCII branch characters instead of unicode
filetree --exclude-dirs dist:build .  # exclude extra directories
```

---


## Installation

Each tool has its own `Makefile`. From any subdirectory:

```bash
make install     # install to /usr/local/bin or /usr/local/sbin
make uninstall   # remove from /usr/local/bin or /usr/local/sbin
```

Tools backed by Docker images (`cast2gif`, `vhs-rec`, `pdf-strip`, `mermaid-render`) pull their image automatically on first run.

## Requirements

| Tool | Requires |
|---|---|
| `asciinema-rec` | `uv` / `uvx`, bash 4+ |
| `cast2gif` | Docker, bash 4+ |
| `vhs-rec` | Docker, bash 4+ |
| `pdf-strip` | Docker, bash 4+ |
| `sanitise-ascii` | Python 3.9+ |
| `mermaid-render` | Docker, bash 4+ |
| `filetree` | bash 4+, `find`, `awk` |
