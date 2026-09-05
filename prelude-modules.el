;;; prelude-modules.el --- A listing of modules to load on startup -*- lexical-binding: t; -*-
;;
;; Copyright © 2011-2025 Bozhidar Batsov
;;
;; Author: Bozhidar Batsov <bozhidar@batsov.com>
;; URL: https://github.com/bbatsov/prelude

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This file is just a list of Prelude modules to load on startup.
;; For convenience the modules are grouped in several categories.
;; The prelude-modules.el in the samples folder should be copied
;; to your personal folder and edited there.

;; Note that some modules can't be used together - e.g. you shouldn't
;; enable both prelude-ido and prelude-ivy, as they serve the same
;; purpose.

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

;; Startup-cost note.  This file is split into two tiers:
;;
;;   * always      -- cheap, and useful for the quick edits you do in
;;                    `emacs -nw' (config files, shell scripts, commit
;;                    messages, C).
;;   * GUI only    -- the heavier, IDE-ish stuff.  Guarded by `my/gui-p'
;;                    (defined in personal/preload/00-early-tweaks.el) so
;;                    terminal Emacs never pays for it.
;;
;; Measured costs of the GUI-only tier on this machine: prelude-xml
;; ~0.30s (pulls in nxml + the rng-* validation stack), prelude-erc
;; ~0.26s, prelude-clojure (CIDER) and prelude-web similar.
;;
;; Move a `require' between the two lists if you find you want it in the
;; terminal after all -- nothing else has to change.

;;; ---------------------------------------------------------------
;;; Always loaded (terminal + GUI)
;;; ---------------------------------------------------------------

;; Completion
(require 'prelude-vertico) ;; A powerful, yet simple, alternative to ivy
(require 'prelude-company)

;; Languages that are cheap to set up and that you also edit in a pinch.
;; Note LSP is *not* required here: the language modules call
;; `prelude-lsp-enable' from their mode hooks, which starts eglot
;; (see `prelude-lsp-client') lazily on the first file you open.
(require 'prelude-emacs-lisp)
(require 'prelude-lisp)   ;; Common setup for Lisp-like languages
(require 'prelude-shell)
(require 'prelude-yaml)
(require 'prelude-c)

;;; ---------------------------------------------------------------
;;; GUI only -- the full IDE setup
;;; ---------------------------------------------------------------

;; `my/gui-modules' lists these (see preload/00-early-tweaks.el):
;;   prelude-org  prelude-clojure  prelude-css  prelude-js
;;   prelude-perl prelude-web      prelude-xml  prelude-erc
;;
;; In a GUI frame they all load.  In `emacs -nw' only the ones you have
;; opted into via `my/terminal-extra-modules' do -- toggle them from the
;; "Terminal tier" section of the welcome screen (M-x prelude-welcome),
;; or with M-x my/terminal-toggle-module.
(dolist (module my/gui-modules)
  (when (or my/gui-p (memq module my/terminal-extra-modules))
    (require module)))

;;; ---------------------------------------------------------------
;;; Available but disabled -- uncomment to enable
;;; ---------------------------------------------------------------

;; (require 'prelude-ido)          ;; Supercharges Emacs completion for C-x C-f and more
;; (require 'prelude-ivy)          ;; A mighty modern alternative to ido
;; (require 'prelude-helm)         ;; Interface for narrowing and search
;; (require 'prelude-helm-everywhere)
;; (require 'prelude-key-chord)    ;; Binds useful features to key combinations
;; (require 'prelude-evil)         ;; vim emulation
;; (require 'prelude-lsp-mode)     ;; only if you prefer lsp-mode over eglot
;; (require 'prelude-corfu)        ;; in-buffer completion, alternative to company
;; (require 'prelude-ai)
;; (require 'prelude-forge)
;; (require 'prelude-apheleia)
;; (require 'prelude-mistty)
;; (require 'prelude-coffee)
;; (require 'prelude-common-lisp)
;; (require 'prelude-dart)
;; (require 'prelude-erlang)
;; (require 'prelude-elixir)
;; (require 'prelude-fsharp)
;; (require 'prelude-go)
;; (require 'prelude-haskell)
;; (require 'prelude-latex)
;; (require 'prelude-literate-programming)
;; (require 'prelude-lua)
;; (require 'prelude-ocaml)
;; (require 'prelude-python)
;; (require 'prelude-racket)
;; (require 'prelude-ruby)
;; (require 'prelude-rust)
;; (require 'prelude-scala)
;; (require 'prelude-scheme)
;; (require 'prelude-scss)
;; (require 'prelude-swift)
;; (require 'prelude-ts)

(provide 'prelude-modules)
;;; prelude-modules.el ends here
