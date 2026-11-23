# Rio Starter Kit

A clean, shareable version of the colored per-project terminal system. Open a
separate [Rio](https://rioterm.com) window for each project, each with its own
background tint, plus a numbered picker when you open a new window.

No personal data, no database wiring, no assumptions about your projects. Edit
one list and you are done. The repo is public, so you can download it with one
command -- no GitHub account or SSH key needed.

## What you get

- A **picker** that lists your projects with color swatches when a new Rio window opens
- `on <name>` to jump straight to a project window
- `p` to open the picker on demand
- Each project window tinted a different color so you can tell them apart
- One editable project list (`RIO_PROJECTS`) that drives both the picker and `on`

## Prerequisites

`install.sh` only wires up config files. It does **not** install Rio, the font, or
Homebrew, so on a clean Mac it will complete successfully and leave you with a kit
that has no terminal to launch. Install these first, in this order:

1. **Xcode Command Line Tools** -- for `git`. Check with `git --version`; if it's
   missing, `xcode-select --install` and let it finish before cloning.
2. **Homebrew** -- https://brew.sh. On Apple Silicon it installs to `/opt/homebrew`
   and is **not** on your PATH until you add it:
   `echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile`.
   That file is only read by login shells, so open a new window afterward.
3. **Rio terminal** -- `brew install --cask rio`, or the `.dmg` from https://rioterm.com
4. **JetBrainsMono Nerd Font** -- `brew install --cask font-jetbrains-mono-nerd-font`.
   Without Homebrew this is a zip of several hundred `.ttf` files installed through
   Font Book -- workable, but slow. Alternatively, change the `family` lines in
   `config/_base.toml` and `config/config.toml` to a font you already have; you lose
   the glyph icons and nothing else.

On a managed/work Mac, confirm you have permission to install apps, fonts, and a
package manager **before** you start -- not halfway through.

> **Setting up a brand-new machine from nothing? Start with [`SETUP.md`](SETUP.md).**
> It's the full annotated walkthrough -- Xcode tools, Homebrew, Rio, the font,
> the two PATH steps that bite everyone, a verification command after each step that
> can fail silently, and a troubleshooting list. It exists because someone already
> lost an afternoon to every warning in it.

## Install

```bash
git clone https://github.com/planginc/rio-starter-kit.git ~/rio-starter-kit
cd ~/rio-starter-kit
bash install.sh
```

Then open a new Rio window (or `source ~/.zshrc`). The picker appears.

`install.sh` is safe to re-run. It copies the kit into `~/.config/rio-kit/`, installs
the root Rio config, generates one color config per project, creates any project
folders that don't exist yet, and adds a single `source` line to `~/.zshrc`.

**Verify it worked:**

```bash
ls ~/.config/rio/projects/     # expect one folder per project
```

An empty directory means the color configs were never generated -- see the
known-bug note in [`SETUP.md`](SETUP.md) Step 5.

Keep all four default projects for your first run. A single entry proves nothing:
the point is the per-project tinting, and you can't see that until two differently
colored windows sit side by side.

## Customize your projects

Your project list lives in **`~/.config/rio-kit/projects.local.sh`** -- a file that
contains nothing but a `RIO_PROJECTS` block. Create it (or edit it, if `install.sh`
migrated one for you):

```bash
cat > ~/.config/rio-kit/projects.local.sh <<'EOF'
RIO_PROJECTS=(
  "home|$HOME|home|Home (plain shell)|#0f0d0e"
  "api|$HOME/code/api|API|API Server|#001a33"
)
EOF
```

Each line is:

```
"alias|/absolute/folder/path|Window Title|Display Name|#hexcolor"
```

Then regenerate the color configs and create any new folders:

```bash
rio-sync-colors
rio-make-dirs
```

That's the only place you edit. The picker numbers and the `on` aliases both
come from this list, so they can never drift apart.

**Why a separate file:** `install.sh` overwrites `zshrc-rio.sh` when you upgrade the
kit, but it never touches `projects.local.sh`. Your projects survive upgrades, and
every machine keeps its own list -- a work laptop can carry a subset of what your
personal desktop has. If the file doesn't exist, the defaults in `zshrc-rio.sh` are
used instead.

### Picking colors

Use dark, low-saturation hex values so text stays readable over the tint.
Good starting palette:

| Color        | Hex       |
|--------------|-----------|
| Deep blue    | `#001a33` |
| Deep teal    | `#00261f` |
| Deep purple  | `#150829` |
| Deep red     | `#2b0808` |
| Deep amber   | `#2b2206` |
| Near-black   | `#0f0d0e` |

## Commands

| Command            | What it does                                   |
|--------------------|------------------------------------------------|
| `p`                | Open the numbered picker                       |
| `on <alias>`       | Open a specific project window                 |
| `rio-sync-colors`  | Rebuild color configs after editing the list   |
| `rio-make-dirs`    | Create any project folders that don't exist    |

## How it works (for the curious)

- Rio reads its config from `$RIO_CONFIG_HOME`. Each project has a folder under
  `~/.config/rio/projects/<alias>/` that is a full config identical to the base
  except for its `[colors] background`.
- `_rio_open` launches Rio with `RIO_CONFIG_HOME` pointed at that folder and
  `cd`'d into the project directory.
- The picker auto-runs on a fresh Rio window via the `RIO_WINDOW` marker env var
  (set in the Rio config) plus an `SHLVL` guard so it does not re-fire in nested
  shells.

## Version compatibility

Tested against **Rio 0.5.27** on macOS 26.6.2 (Apple Silicon). The kit depends on
`RIO_CONFIG_HOME` and the `margin` setting, both present and verified in 0.5.27.

## Uninstall

Remove the `source` line from `~/.zshrc`, delete `~/.config/rio-kit/` (this also
removes your `projects.local.sh`, so copy it somewhere first if you want to keep
your list), and optionally `~/.config/rio/projects/`.
