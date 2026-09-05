# Emacs Prelude — personal configuration

My personal layer on top of [Emacs Prelude](https://github.com/bbatsov/prelude).
Everything here lives in Prelude's `personal/` directory, which Prelude loads
automatically; **nothing outside `personal/` is modified**, so `prelude-update`
never hits a merge conflict.

The theme of this config is a **fast terminal Emacs**: `emacs -nw` starts in
~1.5s with a lean module set, while the GUI gets the full IDE treatment.

## Installing on a new machine

### 1. Prelude itself

```sh
git clone https://github.com/bbatsov/prelude.git ~/.emacs.d
```

### 2. This repo, into Prelude's `personal/`

`personal/` already exists and holds three files owned by Prelude
(`.dir-locals.el` and two `.gitkeep`s), so `git clone` into it would fail —
initialise in place instead:

```sh
cd ~/.emacs.d/personal
git init -b main
git remote add origin <this-repo-url>
git fetch origin
git checkout -B main origin/main
```

This is a *nested* git repo. It leaves the outer Prelude clone untouched:
Prelude keeps tracking its own three files, `prelude-update`'s `git pull`
keeps working, and these files stay untracked there exactly as before.

### 3. First launch

Start Emacs once and let Prelude install its packages. If MELPA 404s on
package tarballs, the archive index is stale — `M-x package-refresh-contents`,
then restart.

## Per-machine prerequisites (not config, must be redone each time)

### Emacs

Emacs 29.1+ is required by Prelude; this config is developed against 31.1.

```sh
brew tap d12frosted/emacs-plus
brew trust d12frosted/emacs-plus     # newer Homebrew requires trusting third-party taps
brew install emacs-plus@31
```

Native compilation is enabled unconditionally by the current formula
(`--with-native-compilation=aot`), so no flag is needed. Note that in practice
the build ships almost no pre-compiled `.eln` for Emacs's own Lisp despite the
`aot`; packages get JIT-compiled as you use them. Native compilation mainly
buys *runtime* speed (font-lock, completion, LSP), not startup.

### `/Applications/Emacs.app`

The formula installs `bin/emacs` as a wrapper script that prefers
`/Applications/Emacs.app` over its own bundle. If that path is a stale symlink
to an older keg, `emacs` will silently run the **old** binary — or fail with a
`dyld: Library not loaded: libtiff.5.dylib` error. Point it at the current keg:

```sh
ln -sfn /usr/local/opt/emacs-plus@31/Emacs.app /Applications/Emacs.app
```

### Optional: faster GUI startup

GUI Emacs is launched by launchd, not by a shell, so it needs
`exec-path-from-shell` to inherit `PATH` — and that spawns `zsh -l -i`, which
sources all of `~/.zshrc`. On my machine that costs ~2.7s.

To avoid it, move the things you actually need (`PATH` additions, `jenv init`,
`AWS_PROFILE`, …) from `~/.zshrc` into `~/.zshenv` or `~/.zprofile`, then
uncomment this line in `preload/00-early-tweaks.el`:

```elisp
(setq exec-path-from-shell-arguments '("-l"))
```

`zsh -l` costs ~0.02s versus ~2.7s for `zsh -l -i`. Terminal Emacs already
skips the whole thing (see below).

## What this config does

### Fast terminal startup

Measured on the machine this was written for:

| | before | after |
|---|-------:|------:|
| terminal (`emacs -nw`) | 4.6–5.1s | ~1.5s |
| GUI | ~5.5s | ~5.5s |

Two changes account for it:

**`exec-path-from-shell` is skipped in the terminal.** Prelude's
`prelude-macos` calls `exec-path-from-shell-initialize` unconditionally, and
for zsh that defaults to spawning `zsh -l -i`. That exists to fix GUI Emacs
inheriting no environment from launchd — but a terminal Emacs is started *by*
your shell and already has it, so it is pure overhead there. It is stubbed out
when there is no window system and we are not a daemon (a daemon has no shell
parent, so it still gets the real thing).

**Heavy modules are GUI-only.** See below.

### Module tiers

`prelude-modules.el` splits modules into two tiers:

- **always** — `vertico`, `company`, `emacs-lisp`, `lisp`, `shell`, `yaml`, `c`
- **GUI-only** (`my/gui-modules`) — `org`, `clojure`, `css`, `js`, `perl`,
  `web`, `xml`, `erc`

The GUI tier is the expensive half: `prelude-xml` costs ~0.30s (it pulls in
nxml plus the `rng-*` validation stack) and `prelude-erc` ~0.26s.

In `emacs -nw` a GUI-tier module loads only if you opt into it. Toggle from the
**Terminal tier** section of the welcome screen (`TAB` to a button, `RET` to
toggle), or `M-x my/terminal-toggle-module`. Enabling takes effect immediately;
disabling needs a restart, since Emacs cannot meaningfully unload a module.

The choice persists to `preload/50-terminal-extras.el`, which is **gitignored
on purpose** — it is per-machine state, and a laptop you use in a terminal and
a desktop you use in a GUI will disagree. The file is optional: the `defvar` in
`00-early-tweaks.el` supplies the `nil` default, and toggling recreates it.

### eglot

eglot needs no switch — it is always on. `prelude-programming` requires
`flycheck-eglot` unconditionally, which pulls eglot in, and `prelude-c` is in
the always-on tier, so C/C++ get `eglot-ensure` even in `emacs -nw`.

For any other language, eglot follows from loading that language's module,
because the modules call `prelude-lsp-enable` from their mode hooks (see
`prelude-lsp-client`, which defaults to `eglot`).

Note that `prelude-lsp` no longer exists upstream — it was renamed to
`prelude-lsp-mode` when Prelude switched its default LSP client to eglot.
Requiring the old name aborts `init.el` partway through.

### Emacs 31 warning suppression

Emacs 31 warns about every file loaded without a `lexical-binding` cookie and
pops `*Warnings*` into a window at startup. On this config that fires 20 times,
almost all of it upstream code (Prelude's own `init.el`, `early-init.el`,
`core/*.el`, plus `zenburn-theme` from ELPA) — nothing actionable, and fixing
it would mean a local diff against 18 Prelude files to re-resolve on every
`prelude-update`.

`00-early-tweaks.el` suppresses **only** that subtype. Warnings are still
logged, just not displayed, and genuine warnings still surface. Delete the form
to check whether a newer Prelude has fixed them.

## Files

| file | purpose |
|------|---------|
| `preload/00-early-tweaks.el` | Loaded *before* Prelude's core — the only point early enough to pre-empt `prelude-macos`. Defines `my/gui-p` and `my/gui-modules`. |
| `preload/50-terminal-extras.el` | Generated; per-machine terminal opt-ins. Gitignored. |
| `prelude-modules.el` | The tiered module list. |
| `prelude-personal.el` | eglot keybindings (deferred via `with-eval-after-load`) and global bindings. |
| `prelude-welcome-extras.el` | Adds the "Terminal tier" section to Prelude's welcome screen. |
| `custom.el` | Written by the customize UI. Gitignored — package state, not config. |

Files in `preload/` are loaded by `init.el` before Prelude's core and modules;
everything else in `personal/` is loaded after them.
