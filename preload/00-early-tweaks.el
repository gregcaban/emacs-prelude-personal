;;; 00-early-tweaks.el --- Loaded before Prelude's core -*- lexical-binding: t; -*-

;;; Commentary:

;; Files in personal/preload/ are loaded by init.el *before* Prelude's
;; core modules, which makes this the only place where we can get ahead
;; of `prelude-macos' and its unconditional `exec-path-from-shell-initialize'.

;;; Code:

;; Emacs 31 warns about every file loaded without a `lexical-binding'
;; cookie, and pops *Warnings* into a window at startup.  On this config
;; that fires 20 times, almost all of it upstream code we do not own
;; (Prelude's own init.el/early-init.el/core/*.el, plus zenburn-theme
;; from ELPA), so there is nothing actionable to do about it here --
;; adding the cookies would mean carrying a local diff against Prelude
;; on 18 files and hand-resolving it on every `prelude-update'.
;;
;; Suppress *only* that one subtype, so genuine warnings still surface.
;; Delete this form if you want them back (e.g. to check whether an
;; upstream release has fixed them).
(defvar warning-suppress-types nil)
(add-to-list 'warning-suppress-types '(files missing-lexbind-cookie))

;; Are we a "real" GUI frame, or `emacs -nw' in a terminal?  Used by
;; personal/prelude-modules.el to keep terminal startup lean while the
;; windowed Emacs gets the full IDE treatment.  `initial-window-system'
;; is set before init.el runs, so this is safe to consult this early.
(defconst my/gui-p (and initial-window-system t)
  "Non-nil when this Emacs was started with a window system.")

;; The heavier, IDE-ish modules.  These load unconditionally in a GUI
;; frame; in `emacs -nw' they load only if listed in
;; `my/terminal-extra-modules'.  personal/prelude-modules.el consumes
;; this list, and the welcome-screen section defined in
;; personal/prelude-welcome-extras.el lets you toggle entries.
(defconst my/gui-modules
  '(prelude-org
    prelude-clojure
    prelude-css
    prelude-js
    prelude-perl
    prelude-web
    prelude-xml
    prelude-erc)
  "Modules loaded automatically in a GUI frame, opt-in in the terminal.")

(defvar my/terminal-extra-modules nil
  "Subset of `my/gui-modules' to also load in terminal Emacs.
Set by `my/terminal-toggle-module', which persists it to
personal/preload/50-terminal-extras.el.  That file is loaded from
this same preload directory, i.e. before the modules are required.")

;; `exec-path-from-shell' solves exactly one problem: a *GUI* Emacs on
;; macOS is launched by launchd rather than by a shell, so it inherits
;; none of the PATH/env from your zsh files.  It fixes that by spawning
;; a login *interactive* shell (`zsh -l -i') and copying the environment
;; back out.
;;
;; A terminal Emacs (`emacs -nw') is started *by* your shell and has
;; already inherited all of that, so the dance is pure overhead there.
;; On this machine `zsh -l -i' costs ~2.7s (oh-my-zsh + `jenv init'),
;; which measured as ~58% of total startup.
;;
;; So stub it out when there is no window system and we're not a daemon
;; (a daemon has no shell parent, so it *does* need the real thing).
;; Pre-`provide'ing the feature also makes prelude-macos's `require' free.
(when (and (eq system-type 'darwin)
           (not initial-window-system)
           (not (daemonp)))
  (provide 'exec-path-from-shell)
  (defun exec-path-from-shell-initialize ()
    "No-op: terminal Emacs already inherited the shell environment."
    nil))

;; For the GUI case the call is still needed, but it does not have to be
;; slow.  `exec-path-from-shell-arguments' defaults to '("-l" "-i") on
;; zsh; the "-i" is what drags in ~/.zshrc (oh-my-zsh, `jenv init', ...).
;; Dropping it takes the spawn from ~2.7s to ~0.02s -- but only do that
;; once the vars you care about (PATH additions, AWS_PROFILE, jenv shims)
;; are set in ~/.zshenv or ~/.zprofile rather than ~/.zshrc.
;; Uncomment after moving them:
;; (setq exec-path-from-shell-arguments '("-l"))

;;; 00-early-tweaks.el ends here
