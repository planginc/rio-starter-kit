#!/bin/bash
# Rio starter-kit installer. Safe to re-run.
#
# What it does:
#   1. Preserves this machine's project list into ~/.config/rio-kit/projects.local.sh
#      (that file is never overwritten -- your projects survive every upgrade)
#   2. Copies the kit into ~/.config/rio-kit/
#   3. Installs the root Rio config into ~/.config/rio/config.toml
#   4. Generates per-project color configs from RIO_PROJECTS
#   5. Creates any project folders in RIO_PROJECTS that don't exist yet
#   6. Adds one `source` line to ~/.zshrc (only if not already present)
#
# It does NOT install Rio, the font, or Homebrew -- see README.md for those,
# or SETUP.md for the full clean-machine walkthrough.

set -u
SRC="$(cd "$(dirname "$0")" && pwd)"
KIT="$HOME/.config/rio-kit"
RIOCFG="$HOME/.config/rio"

echo "==> Installing kit into $KIT"
mkdir -p "$KIT"

# --- rescue an existing project list before we overwrite anything ----------
# Older versions of this kit kept RIO_PROJECTS inside zshrc-rio.sh, which this
# installer replaces. On a machine set up that way, a plain upgrade would throw
# the real project list away and silently restore the shipped defaults. So:
# if the installed copy has a customized list and there is no per-machine file
# yet, migrate the list out to projects.local.sh first. That file is never
# overwritten, here or on any later run.
LOCAL="$KIT/projects.local.sh"
extract_projects() { awk '/^RIO_PROJECTS=\(/{f=1} f{print} f&&/^\)/{exit}' "$1"; }

if [[ -f "$KIT/zshrc-rio.sh" && ! -f "$LOCAL" ]]; then
  installed_list="$(extract_projects "$KIT/zshrc-rio.sh")"
  default_list="$(extract_projects "$SRC/zshrc-rio.sh")"
  if [[ -n "$installed_list" && "$installed_list" != "$default_list" ]]; then
    {
      echo "# Per-machine Rio project list."
      echo "# Migrated automatically from zshrc-rio.sh on $(date +%Y-%m-%d)."
      echo "#"
      echo "# THIS is the file to edit when you add or change a project."
      echo "# install.sh never overwrites it, so your list survives kit updates."
      echo "# After editing, run:  rio-sync-colors && rio-make-dirs"
      echo ""
      echo "$installed_list"
    } > "$LOCAL"
    echo "==> Rescued your existing project list into $LOCAL"
  fi
fi

cp "$SRC/zshrc-rio.sh" "$KIT/zshrc-rio.sh"
cp "$SRC/config/_base.toml" "$KIT/_base.toml"

if [[ -f "$LOCAL" ]]; then
  echo "==> Using your per-machine project list ($LOCAL)"
else
  echo "==> No per-machine list yet; using the shipped defaults"
  echo "    Create $LOCAL to define your own."
fi

echo "==> Installing root Rio config into $RIOCFG/config.toml"
mkdir -p "$RIOCFG/projects"
if [[ -f "$RIOCFG/config.toml" ]]; then
  cp "$RIOCFG/config.toml" "$RIOCFG/config.toml.bak-$(date +%Y%m%d-%H%M%S)"
  echo "    (backed up your existing config.toml)"
fi
cp "$SRC/config/config.toml" "$RIOCFG/config.toml"

echo "==> Generating per-project color configs"
# zshrc-rio.sh is zsh-only (it uses `&!`), so this bash script cannot source it.
# Run the sync in zsh, and let a real failure surface instead of silently
# leaving ~/.config/rio/projects/ empty.
if ! zsh -c "source '$KIT/zshrc-rio.sh' && rio-sync-colors"; then
  echo "!! Could not generate project color configs." >&2
  echo "   Fix the error above, then re-run: bash install.sh" >&2
  exit 1
fi

echo "==> Creating any missing project folders"
# The shipped defaults live under ~/Documents/, which is empty on a fresh Mac.
# Without this, those windows open in directories that do not exist.
if ! zsh -c "source '$KIT/zshrc-rio.sh' && rio-make-dirs"; then
  echo "!! Could not create one or more project folders." >&2
  echo "   Check the paths in RIO_PROJECTS, then re-run: bash install.sh" >&2
  exit 1
fi

LINE="source \"\$HOME/.config/rio-kit/zshrc-rio.sh\""
if grep -qF 'rio-kit/zshrc-rio.sh' "$HOME/.zshrc" 2>/dev/null; then
  echo "==> ~/.zshrc already sources the kit -- skipping"
else
  echo "" >> "$HOME/.zshrc"
  echo "# Rio colored-project launcher (rio-starter-kit)" >> "$HOME/.zshrc"
  echo "$LINE" >> "$HOME/.zshrc"
  echo "==> Added source line to ~/.zshrc"
fi

echo ""
echo "Done. Open a new Rio window (or run 'source ~/.zshrc') to see the picker."
echo "To add or change a project, edit $KIT/projects.local.sh"
echo "then run 'rio-sync-colors' (and 'rio-make-dirs' for any new folder)."
