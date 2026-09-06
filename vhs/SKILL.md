---
name: vhs
description: >
    Record terminal GIF animations from .tape script files using vhs-rec (Docker-backed, wrapping
    VHS by Charmbracelet). Use this skill whenever the user wants to produce a terminal recording
    as a GIF, convert a .tape file to a GIF, record a demo animation, or batch-convert a
    directory of .tape files. Trigger on "record terminal gif", "vhs", "vhs-rec", "tape file",
    "terminal animation", "make a gif from a tape", or any request to turn .tape scripts into
    animated GIF recordings.
---

# vhs Skill

You are producing terminal GIF animations from `.tape` script files using the `vhs-rec` wrapper
script, which handles Docker volume plumbing and Output-line rewriting on top of VHS.

---

## When to use this skill

- User wants to convert a `.tape` file to a GIF
- User wants to produce a terminal demo animation
- User asks to "record a terminal GIF" or "run a tape file"

---

## Quickstart

```bash
# Single tape file
vhs-rec demo.tape

# Directory of tape files
vhs-rec test/

# Multiple tape files
vhs-rec test/m0.tape test/m1.tape

# Pass args directly to vhs
vhs-rec -- validate test/demo.tape
```

---

## Step 0 - Resolve environment and install tool

```bash
if [ "${IS_SANDBOX:-no}" = "yes" ] || [ "${IS_SANDBOX:-no}" = "1" ] || [ "${IS_SANDBOX:-no}" = "true" ]; then
    SKILL_DIR="/mnt/skills/user/vhs"
    cp "$SKILL_DIR/vhs-rec" /usr/local/bin/vhs-rec
    chmod +x /usr/local/bin/vhs-rec
else
    command -v vhs-rec >/dev/null 2>&1 || {
        echo "ERROR: vhs-rec not installed. Run: cd ~/Code/toolbox/vhs && make install" >&2
        exit 1
    }
fi
```

## Step 1 - Check for the tool and Docker

```bash
which vhs-rec
docker info >/dev/null 2>&1 || echo "ERROR: Docker is not running"
```

If `vhs-rec` is missing locally:

```bash
cd ~/Code/toolbox/vhs && make install
```

---

## Step 2 - Determine inputs

Ask the user (or infer from context):

- **Single file**: path to a `.tape` file
- **Directory**: path to a directory containing `.tape` files
- **Multiple files**: space-separated list of `.tape` file paths
- **Explicit output**: `input.tape output.gif`

---

## Step 3 - Run vhs-rec

### Single tape file

```bash
vhs-rec <input.tape>
# output: <input>.gif alongside the input file (Output line rewritten automatically)
```

### Explicit output name

```bash
vhs-rec <input.tape> <output.gif>
```

### Directory

```bash
vhs-rec <directory>/
# converts every .tape file found in the directory
```

### Multiple files

```bash
vhs-rec file1.tape file2.tape file3.tape
```

### Pass-through to vhs

```bash
vhs-rec -- validate demo.tape
vhs-rec -- new test.tape
```

---

## Step 4 - Confirm output

After rendering, confirm the `.gif` file exists:

```bash
ls -lh <output>.gif
file <output>.gif
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

The `Output` line is rewritten automatically by `vhs-rec` -- you don't need to change it.

---

## Environment variables

| Variable | Values | Description |
|---|---|---|
| `DEBUG` | `true`/`1`, `false`/`0` | Enable verbose logging |
| `USE_SHELL` | `zsh`, `bash` | Shell to use in the container |

---

## Exit codes

| Code | Meaning |
|------|---------|
| 0 | All tape files rendered successfully |
| 1 | Input not found, Docker error, or render failed |

---

## Error handling

| Symptom | Likely cause | Fix |
|---|---|---|
| `vhs-rec not found` | Not installed | Run `make install` from `toolbox/vhs/` |
| `Docker not running` | Docker Desktop stopped | Start Docker Desktop |
| `Pull failed` | No network or auth | Run `make docker-build` to build locally |
| GIF missing after render | VHS error in tape | Check stderr; validate tape with `vhs-rec -- validate` |
| Docker commands fail in tape | Docker socket not mounted | The wrapper mounts the Docker socket automatically |
