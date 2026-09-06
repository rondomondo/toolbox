# vhs-rec

[vhs_rec](vhs-rec) is utility script wrapper used to interact with the [ghcr.io/rondomondo/vhs-rec](ghcr.io/rondomondo/vhs-rec:latest) Docker image and that image in turn incorporates the [VHS](https://github.com/charmbracelet/vhs) image.

It adds three main capabilities to the base image functionality:

1) You can now use it to record Docker-related workflows that normally run externally.
2) It includes baked in extra utilities useful in container workflows: make, docker-compose, system utilities, zsh and themes, etc.
3) It also includes additional fonts and themes for recordings.

> **Also available as an [Agent Skill](#claude-code-skill)** -- install it to produce terminal GIF recordings directly from Claude Code with no terminal required. Use the `/vhs` slash command or just describe what you want and your AI Agent will handle it.

## What is VHS
[VHS](https://github.com/charmbracelet/vhs) converts [.tape](https://github.com/charmbracelet/vhs#tutorial) script files into GIF (or other) recordings. Running it
directly as a container requires manually wiring up Docker volume mounts so the
container can read your tape file and write output back to the host.

This wrapper handles all of that automatically: also it rewrites the Output line in
your tape file to the correct filename and mounts the right directory, so you
can pass a single .tape file, multiple .tape files, or a directory full of .tape
files and get GIF files generated for all of them.

Note: calling with '--' passes everything through directly to the vhs app.

---

## Quickstart

### Install from the published ghcr.io image

The [ghcr.io/rondomondo/vhs-rec](ghcr.io/rondomondo/vhs-rec:latest) image understands the `install` command. No volume mount needed:

```bash
setopt interactivecomments

# 1. Stream the vhs-rec wrapper script to disk and make it executable
docker run --rm ghcr.io/rondomondo/vhs-rec install > vhs-rec && chmod +x vhs-rec

# 2. Install it system-wide
install -m 755 vhs-rec /usr/local/bin/vhs-rec

# 3. Generate a test tape file to use
vhs-rec -- new test.tape

# 4. Record a tape file
vhs-rec test.tape

# 5. Done — test.gif should now exist
file test.gif
```


### Install and use from the github repository

```bash
setopt interactivecomments

# 1. Clone the toolbox repo
git clone https://github.com/rondomondo/toolbox.git && cd toolbox/vhs

# 2. Install the wrapper script
make install

# 3. Record a `tape` file using an example from the test directory 
vhs-rec test/test.tape

# 4. Done — vhs/test/test.gif should now exist
file test/test.gif
```

No Docker pull needed upfront; `vhs-rec` pulls `ghcr.io/rondomondo/vhs-rec:latest` automatically on first run.

---

## Installation

From the cloned repository

### Install `vhs-rec` to `/usr/local/bin`

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
vhs-rec                          Show help
vhs-rec -h | --help              Show help only
vhs-rec <input.tape>             Convert one tape → <input>.gif
vhs-rec <input.tape> <out.gif>   Convert one tape with explicit output name
vhs-rec <directory>              Convert every .tape in a directory
vhs-rec <tape1> <tape2> ...      Convert multiple tape files
vhs-rec -- [args...]             Pass args directly to vhs (e.g. validate)
```

The `Output` line inside each `.tape` file is rewritten automatically to match the derived or explicit output path before vhs runs.

### Examples

```bash
# Single file
vhs-rec demo.tape

# Explicit output name
vhs-rec test/test.tape output/my-recording.gif

# Whole directory
vhs-rec test/

# Multiple files
vhs-rec test/m0.tape test/m1.tape test/m2.tape

# Pass args directly to original vhs (passthrough mode)
vhs-rec -- validate test/m0.tape
```

---

## Tape file basics

A `.tape` file describes what to type and when:

```tape
Output demo.gif

Set Shell "zsh"
Set FontSize 16
Set FontFamily "JetBrains Mono"
Set Width 1200
Set Height 700
Set Theme "Catppuccin Mocha"
Set Padding 20

Type "echo hello"
Sleep 1s
Enter
Sleep 3s
```

See [test/](test/) for working examples including Catppuccin Mocha and Tokyo Night themes.

---

## What's in the image

Built on `ghcr.io/charmbracelet/vhs:latest` with:

| Category | Included |
|---|---|
| Shell | zsh + Oh My Zsh (philips theme) |
| Dev tools | git, make, golang, python3 (uv), docker, docker-compose, curl, wget |
| Fonts | JetBrains Mono, JetBrains Mono Nerd Font, Fira Code, Cascadia Code |
| Extras | sudo, htop, lsof, ssh-client, iproute2, dnsutils |

The container user (`vhs`) has passwordless sudo and is added to the `docker` group, so recordings can run real Docker commands.

---

## Docker targets

```bash
make docker-build              # Build image locally
make docker-ensure             # Pull from ghcr.io (or build if unavailable)
make docker-shell              # Drop into a zsh shell in the container
make docker-release            # Build + push versioned tag and :latest
make docker-clean              # Remove local image
```

Override the tag or registry:

```bash
make docker-build VHS_IMAGE_TAG=0.0.4
make docker-push  REGISTRY=docker.io
```

---

## Requirements

- Docker (running locally)
- `bash` 4+
- `make` (for Makefile targets)

---

## Claude Code skill

<details>
<summary>Install the <code>/vhs</code> slash command for Claude Code</summary>

This repository ships a `/vhs` slash command skill for [Claude Code](https://claude.ai/code)
that lets Claude produce terminal GIF recordings -- no terminal required. Just describe what
you want and Claude will invoke the skill automatically.

### What it accepts

| Input | Example |
|---|---|
| Single tape file | `demo.tape` |
| Directory | `test/` |
| Multiple files | `m0.tape m1.tape m2.tape` |

### Invoking the skill

Use the slash command directly:

```
/vhs demo.tape
/vhs test/
/vhs m0.tape m1.tape
```

Or just describe what you want in natural language -- Claude will invoke the skill automatically:

> *"Record a terminal GIF of the make install command"*
>
> *"Convert test/demo.tape to an animated GIF"*

### Installing the skill

#### Option A -- sync locally via `make`

```bash
# from inside the vhs directory
make sync-skill
```

This syncs `vhs-rec`, `SKILL.md`, and `README.md` to:

```
~/Code/agent-skills-toolbox/skills/vhs/
```

Override the target directory with `SKILLS_DIR`:

```bash
make sync-skill SKILLS_DIR=/path/to/your/project/.claude/skills/vhs
```

#### Option B -- copy manually

```bash
mkdir -p .claude/skills/vhs
cp vhs-rec SKILL.md README.md .claude/skills/vhs/
```

</details>
