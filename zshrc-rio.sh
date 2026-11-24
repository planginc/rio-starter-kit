# ============================================================================
# Rio colored-project launcher
# ----------------------------------------------------------------------------
# Source this from your ~/.zshrc:   source ~/.config/rio-kit/zshrc-rio.sh
# (install.sh adds that line for you.)
#
# Opens a separate Rio terminal window per project, each with its own
# background tint so you can tell your windows apart at a glance.
#
# TO ADD / CHANGE PROJECTS: edit your per-machine list at
#   ~/.config/rio-kit/projects.local.sh
# (NOT the defaults below -- install.sh overwrites this file, but never that
# one). Then run:
#   rio-sync-colors    (re)generate the per-project color configs
#   rio-make-dirs      create any project folders that don't exist yet
# Both the `on` command and the numbered picker read from that one list.
# ============================================================================

# Each entry: "alias|/absolute/folder/path|Window Title|Display Name|#hexcolor"
#   alias        short name -> `on <alias>` and the color-config folder name
#   folder       absolute path the window opens in
#   Window Title text shown in the macOS title bar
#   Display Name text shown in the numbered picker
#   #hexcolor    window background tint (also the picker swatch)
RIO_PROJECTS=(
  "home|$HOME|home|Home (plain shell)|#0f0d0e"
  "work|$HOME/Documents/work|work|Work Project|#001a33"
  "notes|$HOME/Documents/notes|notes|Notes|#00261f"
  "scratch|$HOME/Documents/scratch|scratch|Scratch|#150829"
)

# --- per-machine project list (this is the file you actually edit) ---------
# The list above is only a starting default. Your real projects belong in:
#
#     ~/.config/rio-kit/projects.local.sh
#
# which contains nothing but its own RIO_PROJECTS=( ... ) block. install.sh
# NEVER writes or overwrites that file, so:
#   - each machine keeps its own project list (a work laptop can carry a
#     subset of what a desktop has)
#   - re-running install.sh to pick up kit updates is safe and will not
#     replace your projects with the defaults above
# If the file doesn't exist, the defaults above are used.
RIO_PROJECTS_LOCAL="${RIO_PROJECTS_LOCAL:-$HOME/.config/rio-kit/projects.local.sh}"
[[ -f "$RIO_PROJECTS_LOCAL" ]] && source "$RIO_PROJECTS_LOCAL"

RIO_BIN="/Applications/Rio.app/Contents/MacOS/rio"
RIO_CONF_ROOT="$HOME/.config/rio/projects"

# --- open a project window -------------------------------------------------
_rio_open() {
  local dir="$1" conf="$2" title="${3:-}"
  # Fail loudly. Without these checks a missing Rio or a missing project folder
  # makes `on` and the picker do nothing at all, with no clue why.
  if [[ ! -x "$RIO_BIN" ]]; then
    echo "Rio not found at $RIO_BIN" >&2
    echo "Install it with:  brew install --cask rio" >&2
    echo "(or download the .dmg from https://rioterm.com)" >&2
    return 1
  fi
  if [[ ! -d "$dir" ]]; then
    echo "Project folder does not exist: $dir" >&2
    echo "Create the missing folders with:  rio-make-dirs" >&2
    return 1
  fi
  if [[ -n "$title" ]]; then
    # Rio 0.5.30+ has --title, which pins the title so zsh and Claude Code can't
    # replace it. Older Rio only has --title-placeholder (a starting title that
    # the shell overwrites) and rejects --title outright, so check before using it.
    if [[ -z "${_RIO_TITLE_FLAG:-}" ]]; then
      if "$RIO_BIN" --help 2>/dev/null | grep -q -- '--title <'; then
        _RIO_TITLE_FLAG="--title"
      else
        _RIO_TITLE_FLAG="--title-placeholder"
      fi
    fi
    (cd "$dir" && RIO_CONFIG_HOME="$RIO_CONF_ROOT/$conf" "$RIO_BIN" "$_RIO_TITLE_FLAG" "$title") &!
  else
    (cd "$dir" && RIO_CONFIG_HOME="$RIO_CONF_ROOT/$conf" "$RIO_BIN") &!
  fi
}

# --- `on <alias>` : open a project by name ---------------------------------
on() {
  local want="$1" entry a folder title
  for entry in "${RIO_PROJECTS[@]}"; do
    a="${entry%%|*}"
    if [[ "$a" == "$want" ]]; then
      folder="$(echo "$entry" | cut -d'|' -f2)"
      title="$(echo "$entry" | cut -d'|' -f3)"
      # Propagate _rio_open's status -- a failed launch must not report success.
      _rio_open "$folder" "$a" "$title"
      return $?
    fi
  done
  echo "Unknown project '$want'. Available:"
  for entry in "${RIO_PROJECTS[@]}"; do echo "  ${entry%%|*}"; done
  return 1
}

# --- color swatch helper (true-color block) --------------------------------
_cs() { local h="$1"; printf "\033[48;2;%d;%d;%dm   \033[0m" $((16#${h:1:2})) $((16#${h:3:2})) $((16#${h:5:2})); }

# --- numbered picker -------------------------------------------------------
_rio_project_picker() {
  local i=1 entry hex name
  echo ""
  echo "  Which project?"
  echo ""
  for entry in "${RIO_PROJECTS[@]}"; do
    name="$(echo "$entry" | cut -d'|' -f4)"
    hex="$(echo "$entry" | cut -d'|' -f5)"
    printf "  %s  %2d  %s\n" "$(_cs "$hex")" "$i" "$name"
    i=$((i+1))
  done
  echo ""
  printf "  Number (or blank to cancel): "
  read -r _pick
  [[ -z "$_pick" ]] && { echo "  Cancelled."; return; }
  entry="${RIO_PROJECTS[$_pick]}"        # zsh arrays are 1-based
  if [[ -z "$entry" ]]; then echo "  No such number."; return; fi
  local a folder title
  a="${entry%%|*}"
  folder="$(echo "$entry" | cut -d'|' -f2)"
  title="$(echo "$entry" | cut -d'|' -f3)"
  _rio_open "$folder" "$a" "$title"
}
alias p="_rio_project_picker"

# --- regenerate per-project color configs from the list --------------------
rio-sync-colors() {
  local base="$HOME/.config/rio-kit/_base.toml" entry a hex dir
  if [[ ! -f "$base" ]]; then echo "Missing $base -- run install.sh first."; return 1; fi
  for entry in "${RIO_PROJECTS[@]}"; do
    a="${entry%%|*}"
    hex="$(echo "$entry" | cut -d'|' -f5)"
    dir="$RIO_CONF_ROOT/$a"
    mkdir -p "$dir"
    { cat "$base"; printf "\n[colors]\nbackground = '%s'\n" "$hex"; } > "$dir/config.toml"
  done
  echo "Synced ${#RIO_PROJECTS[@]} project color configs into $RIO_CONF_ROOT."
}

# --- create any project folders that don't exist yet -----------------------
# The shipped defaults point at ~/Documents/{work,notes,scratch}, which do not
# exist on a fresh Mac. install.sh calls this so a new machine works out of the
# box; run it yourself after adding a project to RIO_PROJECTS.
rio-make-dirs() {
  local entry folder made=0
  for entry in "${RIO_PROJECTS[@]}"; do
    folder="$(echo "$entry" | cut -d'|' -f2)"
    if [[ ! -d "$folder" ]]; then
      if mkdir -p "$folder"; then
        echo "  created $folder"
        made=$((made+1))
      else
        echo "!! Could not create $folder" >&2
        return 1
      fi
    fi
  done
  if [[ $made -eq 0 ]]; then
    echo "All ${#RIO_PROJECTS[@]} project folders already exist."
  else
    echo "Created $made missing project folder(s)."
  fi
}

# Auto-run the picker when a NEW Rio window opens (not nested shells).
# RIO_WINDOW is set by the Rio config; SHLVL guard avoids re-firing in subshells.
if [[ -n "${RIO_WINDOW:-}" && "$SHLVL" -eq 1 && -o interactive ]]; then
  _rio_project_picker
fi
