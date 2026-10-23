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

;;; Python
;;
;; LSP: `prelude-python' runs `prelude-lsp-enable' (eglot) from the mode
;; hook, and eglot picks basedpyright-langserver off PATH.  basedpyright
;; finds the project's .venv by itself, so there is nothing to configure.
;;
;; Tests and REPL are laid out after CIDER: C-c C-t for tests, C-c C-k to
;; load the buffer into the REPL, C-c C-z to jump to it.

(prelude-require-package 'python-pytest)

;; `python-pytest-executable' is run through a shell, so "uv run" works
;; and keeps the venv in sync before each run.
(setq python-pytest-executable "uv run pytest")

;; One REPL per project, started in the project root.
(setq python-shell-dedicated 'project)

(defun my/python--find-venv ()
  "Nearest .venv or venv directory at or above this file, or nil."
  (seq-some (lambda (name)
              (when-let* ((dir (locate-dominating-file default-directory name))
                          (venv (expand-file-name name dir))
                          ((file-executable-p (expand-file-name "bin/python" venv))))
                venv))
            '(".venv" "venv")))

(defun my/python--project-root ()
  "Directory the REPL should start in: the project root, else the venv's parent."
  (or (seq-some (lambda (marker) (locate-dominating-file default-directory marker))
                '("pyproject.toml" "setup.py" "setup.cfg"))
      (when-let* ((venv (my/python--find-venv)))
        (file-name-directory (directory-file-name venv)))
      (when-let* ((project (project-current))) (project-root project))
      default-directory))

(defun my/python-use-project-venv ()
  "Point `run-python' at the nearest venv above this file."
  (when-let* ((venv (my/python--find-venv)))
    (setq-local python-shell-virtualenv-root venv)
    (setq-local python-shell-interpreter (expand-file-name "bin/python" venv))))

(add-hook 'python-base-mode-hook #'my/python-use-project-venv)

(defun my/python-jack-in (&optional restart)
  "Start the project REPL in the project root with the project's venv.
Like `cider-jack-in'.  If a REPL is already running, switch to it;
with a prefix argument, kill it and start a fresh one."
  (interactive "P")
  (my/python-use-project-venv)
  (let ((proc (python-shell-get-process)))
    (when (and proc restart)
      (let ((kill-buffer-query-functions nil))
        (kill-buffer (process-buffer proc)))
      (setq proc nil))
    (if proc
        (pop-to-buffer (process-buffer proc))
      (let ((default-directory (my/python--project-root)))
        (run-python nil python-shell-dedicated t)
        (message "REPL: %s in %s"
                 (or python-shell-virtualenv-root python-shell-interpreter)
                 (abbreviate-file-name default-directory))))))

(defun my/python--module-name ()
  "Return (MODULE . SYS-PATH-ROOT) for this file.
Walks up through directories that have an __init__.py, so
oxpecker/gen/builder.py is (\"oxpecker.gen.builder\" . \"<repo>/\")."
  (let* ((file (buffer-file-name))
         (base (file-name-base file))
         (dir (file-name-directory file))
         (parts (unless (equal base "__init__") (list base))))
    (while (file-exists-p (expand-file-name "__init__.py" dir))
      (push (file-name-nondirectory (directory-file-name dir)) parts)
      (setq dir (file-name-directory (directory-file-name dir))))
    (cons (string-join parts ".") dir)))

(defconst my/python--load-helper "
def __el_load(tmp, modname, path, root):
    import importlib.util, os, sys, __main__
    if root not in sys.path:
        sys.path.insert(0, root)
    with open(tmp, encoding='utf-8') as f:
        src = f.read()
    os.remove(tmp)
    mod = sys.modules.get(modname)
    if mod is None:
        spec = importlib.util.find_spec(modname)
        mod = importlib.util.module_from_spec(spec)
        sys.modules[modname] = mod
    exec(compile(src, path, 'exec'), mod.__dict__)
    __main__.__dict__.update({k: v for k, v in mod.__dict__.items()
                              if not k.startswith('__')})
    print(f'; loaded {modname}')
"
  "Defined in the REPL before each load; see `my/python--send-buffer-and-show'.")

(defun my/python--send-buffer-and-show ()
  "Evaluate the buffer inside its real module, then expose its names in the REPL.
Relative imports resolve, the `if __name__ == \"__main__\"' block does
not run, and redefinitions replace the module's objects in place, so
other modules holding references to it see them."
  (unless (buffer-file-name)
    (user-error "Buffer is not visiting a file"))
  (require 'json)
  (let* ((mod (my/python--module-name))
         (tmp (make-temp-file "el-python-load" nil ".py")))
    (write-region nil nil tmp nil 'silent)
    (python-shell-send-string
     (concat my/python--load-helper
             (format "__el_load(%s, %s, %s, %s)\n"
                     (json-encode-string tmp)
                     (json-encode-string (car mod))
                     (json-encode-string (buffer-file-name))
                     (json-encode-string (expand-file-name (cdr mod))))))
    (display-buffer (process-buffer (python-shell-get-process)))))

(defun my/python-load-buffer ()
  "Load the buffer into the project REPL, starting it if needed.
Like CIDER's `cider-load-buffer'."
  (interactive)
  (if (python-shell-get-process)
      (my/python--send-buffer-and-show)
    ;; A fresh REPL drops input sent before its first prompt, so wait
    ;; for it (and step out of python.el's bootstrap hook) first.
    (let ((source (current-buffer)))
      (save-window-excursion (my/python-jack-in))
      (with-current-buffer (process-buffer (python-shell-get-process))
        (add-hook 'python-shell-first-prompt-hook
                  (lambda ()
                    (run-at-time 0 nil (lambda ()
                                         (with-current-buffer source
                                           (my/python--send-buffer-and-show)))))
                  nil t)))))

(defvar-keymap my/python-test-map
  :doc "CIDER-style pytest commands, under C-c C-t."
  "t" #'python-pytest-run-def-or-class-at-point-dwim ; test at point
  "n" #'python-pytest-file-dwim                      ; this file's tests
  "p" #'python-pytest                                ; whole project
  "r" #'python-pytest-last-failed                    ; re-run failures
  "g" #'python-pytest-repeat                         ; repeat last run
  "m" #'python-pytest-dispatch)                      ; transient menu

(with-eval-after-load 'python
  ;; Replaces python.el's C-c C-t skeleton prefix.
  (define-key python-base-mode-map (kbd "C-c C-t") my/python-test-map)
  (define-key python-base-mode-map (kbd "C-c C-k") 'my/python-load-buffer)
  (define-key python-base-mode-map (kbd "C-c M-j") 'my/python-jack-in))

(provide 'prelude-personal)
;;; prelude-personal.el ends here
