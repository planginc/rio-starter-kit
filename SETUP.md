# Setting up the Rio Starter Kit on a clean Mac

A step-by-step path from a Mac with **nothing installed** to a working colored-project
terminal. Follow the steps in order -- nothing here depends on something installed in a
later step.

This was written by walking a brand-new Apple Silicon Mac (macOS 26.6.2, fresh user
account, admin rights, no developer tooling at all) through the whole process and
writing down every place it went wrong. Most of the warnings below exist because
somebody already lost time to them.

> **On a managed / MDM work laptop this path diverges.** You may not have admin rights,
> and IT may block Homebrew, unsigned apps, or font installation outright. Every step
> that needs admin or a package manager notes its manual fallback. Confirm what you're
> permitted to install **before** you start, not halfway through.

Placeholders used below:

| Placeholder | Means |
|---|---|
| `<your-github-username>` | The GitHub account you'll push from |
| `<your-mac-username>` | Your macOS short username (what `whoami` prints) |

**Roughly how long:** 20-40 minutes, most of it waiting on downloads.

---

## Step 0 -- Install Claude Code (optional, but assumed below)

Skip this if you don't use Claude Code and are following the steps by hand.

These instructions assume you can type `claude` and get a session. On a clean machine
that command doesn't exist yet -- you'll get `zsh: command not found: claude`.

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

**The PATH step is mandatory and easy to skim past.** The installer puts the binary in
`~/.local/bin`, which is not on PATH on a clean macOS account. It prints the fix, but if
you miss it the next command fails in a way that looks like a broken install:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Verify before continuing:

```bash
which claude        # expect: /Users/<your-mac-username>/.local/bin/claude
```

**First launch runs onboarding:** a theme picker, then authentication, then an offer to
enable a new fullscreen renderer. **Decline the renderer for now** -- if you enable two
unfamiliar renderers at once, any display weirdness later is ambiguous, and you want Rio
problems to be attributable to Rio.

**There is usually a pending update on first launch.** Run `/exit` and relaunch before
starting real work.

> Note: `claude auth login` is **not** a real command, despite appearing in various
> guides. Authentication happens during first launch, and `/login` inside a session
> afterward.

---

## Step 1 -- Xcode Command Line Tools (for `git`)

You need `git` before you can clone anything. On some Macs it's already there; on others
this kicks off a multi-minute install you do not want firing in the middle of a clone.

```bash
git --version
```

If that prints a version, skip ahead. Otherwise install it and **wait for it to finish**:

```bash
xcode-select --install
```

---

## Step 2 -- Homebrew (a real decision, not a formality)

Rio and the Nerd Font both come from Homebrew, and it's the path this kit is tested on.

**On a work laptop, installing a package manager is a decision to make deliberately.**
If your IT policy discourages or blocks it, skip to the manual fallback in Step 3 -- the
kit works fine either way.

> **Run this in a normal Terminal window.** It needs a real TTY for its password prompt.
> Piping stdin to it -- which is what happens if you run it through Claude Code's `!`
> prefix -- prevents the prompt from opening, and it dies with a misleading message:
>
> `Need sudo access on macOS (e.g. the user <your-mac-username> needs to be an Administrator)!`
>
> It prints that whenever the sudo check fails, **including when you genuinely are an
> admin**. The error is about the missing TTY, not your permissions.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Then the PATH step -- the same failure shape as Step 0.** On Apple Silicon, Homebrew
installs to `/opt/homebrew` and is not on your PATH until you add it. The installer
creates `~/.zprofile` if it doesn't exist and prints a "Next steps" block. If you miss it:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
```

`~/.zprofile` is only read by **login** shells, so a terminal you already had open will
still say `command not found: brew`. Open a new window, or run
`eval "$(/opt/homebrew/bin/brew shellenv)"` in the current one.

```bash
brew --version
```

---

## Step 3 -- Rio and the font

```bash
brew install --cask rio font-jetbrains-mono-nerd-font
```

Verify:

```bash
ls -d /Applications/Rio.app        # note the capital R
```

**Manual fallback (no Homebrew):**

- **Rio** -- download the `.dmg` from https://rioterm.com and drag it to `/Applications`.
- **The font** -- JetBrainsMono Nerd Font ships as a zip of several hundred `.ttf` files
  installed through Font Book. It works, but budget time for it, and you only need the
  Regular, Bold, and Italic faces.
- Or skip the font entirely: change the `family` lines in `config/_base.toml` and
  `config/config.toml` to a font you already have. You lose the glyph icons, nothing else.

---

## Step 4 -- GitHub SSH access (skip it)

**You can skip this whole step.** This repo is public, so Step 5 downloads it over
HTTPS with no GitHub account and no key. Only do this step if you plan to push your own
changes to GitHub over SSH.

This step has a **manual interrupt in the middle** -- a tool can generate the key and
write the config, but a human has to paste the public key into GitHub's web UI.

```bash
ssh-keygen -t ed25519 -C "<your-github-username>" -f ~/.ssh/id_ed25519_<your-github-username> -N ""
pbcopy < ~/.ssh/id_ed25519_<your-github-username>.pub
```

Paste it at https://github.com/settings/ssh/new **while logged in as the account you
actually want to push from**. If your browser is signed into a different account, the key
lands on the wrong one and the failure shows up later as a confusing permissions error.

Then point `~/.ssh/config` at it:

```
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_<your-github-username>
  IdentitiesOnly yes
  AddKeysToAgent yes
  UseKeychain yes
```

> **Warning -- this breaks other GitHub accounts on the same Mac.** `IdentitiesOnly yes`
> on a plain `Host github.com` block routes *every* GitHub connection through this one
> key, so repos belonging to another account stop authenticating. If that applies to you,
> use an alias block instead:
>
> ```
> Host github-<your-github-username>
>   HostName github.com
>   User git
>   IdentityFile ~/.ssh/id_ed25519_<your-github-username>
>   IdentitiesOnly yes
> ```
>
> and clone with `git@github-<your-github-username>:owner/repo.git`. **Don't let a tool
> overwrite an existing `~/.ssh/config` without looking at it first.**

> **Warning -- that key has no passphrase.** `-N ""` is what lets it be generated
> non-interactively. That's a deliberate convenience tradeoff, not a default to inherit
> silently. Add one later with:
> `ssh-keygen -p -f ~/.ssh/id_ed25519_<your-github-username>`

Verify:

```bash
ssh -T git@github.com
```

**This "fails" on success.** It exits with code 1 every time, even when everything is
correct. The greeting is what tells you it worked:
`Hi <your-github-username>! You've successfully authenticated, but GitHub does not provide shell access.`
Read the greeting, ignore the exit code.

---

## Step 5 -- Clone and install the kit

```bash
git clone https://github.com/planginc/rio-starter-kit.git ~/rio-starter-kit
cd ~/rio-starter-kit
bash install.sh
```

`install.sh` is safe to re-run. It preserves your project list, copies the kit into
`~/.config/rio-kit/`, installs the root Rio config, generates one color config per
project, creates any missing project folders, and adds a single `source` line to
`~/.zshrc`.

**Verify -- this is the step with the historically silent failure:**

```bash
ls ~/.config/rio/projects/     # expect one folder per project
```

An **empty** directory means the color configs were never generated and the picker will
have nothing to show.

> **Known bug on clones from before 2026-09-03.** `install.sh` ran under bash but sourced
> `zshrc-rio.sh`, which is zsh-only (it uses `&!`). The source aborted on a syntax error,
> so `rio-sync-colors` was never defined -- and the failure was suppressed with
> `>/dev/null 2>&1 || true`, so the installer printed "Generating per-project color
> configs" and exited 0 with an empty `projects/` directory. Fixed in `4b5df7a`. If you
> see the empty-directory symptom, `git pull` and re-run.

**Keep all the default projects for your first run.** It's tempting to trim the list to
one, but a single entry proves nothing -- the whole point is the per-project tinting, and
you can't see that working until two windows sit side by side in different colors.

---

## Step 6 -- Verify

```bash
source ~/.zshrc
```

1. **Open a new Rio window.** The numbered picker appears on its own, with a color swatch
   beside each project.
2. **Pick one.** A new window opens, tinted, sitting in that project's folder.
3. **Run `on <alias>`** from any shell to jump straight to a project.
4. **Run `p`** to bring the picker up on demand.

Two windows open in different colors means everything is wired correctly.

---

## Step 7 -- Make it yours

Your project list lives in **`~/.config/rio-kit/projects.local.sh`** -- and *only* there.
`install.sh` never overwrites that file, so your projects survive every kit upgrade, and
each machine keeps its own list.

```bash
cat > ~/.config/rio-kit/projects.local.sh <<'EOF'
RIO_PROJECTS=(
  "home|$HOME|home|Home (plain shell)|#0f0d0e"
  "api|$HOME/code/api|API|API Server|#001a33"
  "web|$HOME/code/web|Web|Web Frontend|#00261f"
)
EOF

rio-sync-colors    # rebuild the color configs
rio-make-dirs      # create any folders that don't exist yet
```

Each line is `"alias|/absolute/folder/path|Window Title|Display Name|#hexcolor"`.

Use dark, low-saturation colors so text stays readable over the tint:
`#001a33` blue, `#00261f` teal, `#150829` purple, `#2b0808` red, `#2b2206` amber,
`#0f0d0e` near-black.

---

## Troubleshooting

**`zsh: command not found: claude`**
Claude Code isn't installed, or `~/.local/bin` isn't on PATH -- Step 0.

**`zsh: command not found: brew`**
`/opt/homebrew` isn't on PATH in this window. `~/.zprofile` is only read by login shells,
so open a new window, or run `eval "$(/opt/homebrew/bin/brew shellenv)"` -- Step 2.

**Picker doesn't appear when opening a new Rio window**
Run `source ~/.zshrc`, then open a new window. If it still doesn't appear:
`grep rio-kit ~/.zshrc` -- if nothing shows, the source line wasn't added. Re-run
`bash install.sh`.

**Picker appears but has no projects, or `~/.config/rio/projects/` is empty**
The color configs were never generated. On an old clone this failed silently -- see the
known-bug note in Step 5. `git pull`, then re-run `bash install.sh`.

**`on <name>` says "unknown project"**
The alias doesn't match anything in your list. Run `p` to see the current aliases.

**Nothing happens when you pick a project**
Rio isn't where the kit expects it: `ls -d /Applications/Rio.app`. If missing,
`brew install --cask rio`.

**A project window won't open, or reports a missing folder**
The path in your list doesn't exist. Run `rio-make-dirs`.

**Colors look wrong or configs are missing**
Run `rio-sync-colors`.

**Font looks wrong (symbols show as boxes)**
The Nerd Font isn't installed or isn't selected. `brew install --cask font-jetbrains-mono-nerd-font`,
then check that the `family` line in `~/.config/rio-kit/_base.toml` says
`JetBrainsMono Nerd Font`.

**Your projects vanished and the defaults came back**
You're on a version from before `f6a61a9`, where the list lived inside `zshrc-rio.sh` and
`install.sh` overwrote it. `git pull` and re-run `install.sh` -- it will migrate your list
into `projects.local.sh`, after which upgrades are safe.

---

## Where things live

| What | Where |
|---|---|
| **Your project list (edit this)** | `~/.config/rio-kit/projects.local.sh` |
| Kit code + shipped defaults (don't edit) | `~/.config/rio-kit/zshrc-rio.sh` |
| Shared Rio visual config | `~/.config/rio-kit/_base.toml` |
| Per-project color configs (generated) | `~/.config/rio/projects/<alias>/config.toml` |
| Root Rio config (no project) | `~/.config/rio/config.toml` |
| The cloned kit | `~/rio-starter-kit/` |

## Uninstall

Remove the `source` line from `~/.zshrc`, delete `~/.config/rio-kit/` (copy
`projects.local.sh` somewhere first if you want to keep your list), and optionally
`~/.config/rio/projects/`.
