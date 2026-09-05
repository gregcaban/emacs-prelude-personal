;;; prelude-personal.el --- Personal tweaks -*- lexical-binding: t; -*-

;;; Commentary:

;; Loaded by init.el after Prelude's core and modules.

;;; Code:

;;; Don't let Prelude reformat whitespace on save in C-family buffers.
(dolist (hook '(c-mode-common-hook c++-mode-hook java-mode-hook))
  (add-hook hook (lambda () (remove-hook 'before-save-hook 'prelude-cleanup-maybe))))

;;; Eglot
;;
;; Note: there is deliberately no top-level (require 'eglot) here.  It
;; cost ~0.13s on every single startup, including the ones where you
;; never open a C file.  Eglot is started on demand instead:
;; `prelude-c' calls `prelude-lsp-enable' from the C mode hooks, which
;; runs `eglot-ensure' (see `prelude-lsp-client', default `eglot').
;;
;; `eglot-server-programs' already maps c-mode/c++-mode to clangd, so
;; the previous (add-to-list 'eglot-server-programs '((c++-mode c-mode)) "clangd")
;; was both unnecessary and malformed -- "clangd" landed in add-to-list's
;; APPEND argument rather than in the entry, and the entry itself had no
;; program attached.
;;
;; Keybindings go in `with-eval-after-load' so that merely *defining*
;; them doesn't drag eglot in at startup.
(with-eval-after-load 'eglot
  (define-key eglot-mode-map (kbd "C-c r")   'eglot-rename)
  (define-key eglot-mode-map (kbd "C-c o")   'imenu)
  (define-key eglot-mode-map (kbd "C-c i i") 'eglot-completion-at-point)
  (define-key eglot-mode-map (kbd "C-c M-.") 'eglot-code-action-quickfix)
  (define-key eglot-mode-map (kbd "C-c h")   'eldoc)
  (define-key eglot-mode-map (kbd "C-c i m") 'eglot-code-action-organize-imports)
  (define-key eglot-mode-map (kbd "C-c M-e") 'eglot-code-action-extract)
  (define-key eglot-mode-map (kbd "C-c i n") 'eglot-code-action-inline))

;;; Global keybindings
(global-set-key (kbd "C-c M-i") 'imenu)
(global-set-key (kbd "C-c c") 'compile)

(provide 'prelude-personal)
;;; prelude-personal.el ends here
