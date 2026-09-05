;;; prelude-welcome-extras.el --- Terminal tier UI -*- lexical-binding: t; -*-

;;; Commentary:

;; `emacs -nw' deliberately loads a lean set of modules so that it starts
;; fast; the heavier, IDE-ish ones (`my/gui-modules') are GUI-only by
;; default.  This file adds a "Terminal tier" section to the Prelude
;; welcome screen so you can opt individual modules back into the
;; terminal without hunting through config files.
;;
;; The choice is persisted to personal/preload/50-terminal-extras.el,
;; which is loaded early enough (preload runs before the modules are
;; required) to take effect on the next start.

;;; Code:

(defvar my/gui-modules)
(defvar my/terminal-extra-modules)
(defvar my/gui-p)
(defvar prelude-personal-dir)

(defun my/terminal-extras-file ()
  "Return the file that persists `my/terminal-extra-modules'."
  (expand-file-name "preload/50-terminal-extras.el" prelude-personal-dir))

(defun my/terminal-extras-save ()
  "Write `my/terminal-extra-modules' to `my/terminal-extras-file'."
  (with-temp-file (my/terminal-extras-file)
    (insert ";;; 50-terminal-extras.el --- Terminal module opt-ins -*- lexical-binding: t; -*-\n\n"
            ";;; Commentary:\n\n"
            ";; Generated file -- normally written by `my/terminal-toggle-module'\n"
            ";; (see the \"Terminal tier\" section of the welcome screen).  Editing it\n"
            ";; by hand is fine too; it is loaded from personal/preload/, so it takes\n"
            ";; effect before personal/prelude-modules.el requires the modules.\n\n"
            ";;; Code:\n\n"
            (format "(setq my/terminal-extra-modules %s)\n\n"
                    (if my/terminal-extra-modules
                        (format "'%S" my/terminal-extra-modules)
                      "nil"))
            ";;; 50-terminal-extras.el ends here\n")))

;;;###autoload
(defun my/terminal-toggle-module (module)
  "Toggle whether MODULE is loaded by terminal Emacs.

Enabling also requires MODULE right now, so it works in this session;
disabling only takes effect on the next start, since Emacs cannot
meaningfully unload a module once it is in."
  (interactive
   (list (intern (completing-read
                  "Toggle module in terminal tier: "
                  (mapcar #'symbol-name my/gui-modules) nil t))))
  (if (memq module my/terminal-extra-modules)
      (progn
        (setq my/terminal-extra-modules
              (delq module my/terminal-extra-modules))
        (my/terminal-extras-save)
        (message "%s disabled for terminal Emacs (restart to take effect)" module))
    (setq my/terminal-extra-modules
          (append my/terminal-extra-modules (list module)))
    (my/terminal-extras-save)
    (if (require module nil t)
        (message "%s enabled for terminal Emacs (loaded now)" module)
      (message "%s enabled for terminal Emacs (but failed to load now)" module)))
  (when (derived-mode-p 'prelude-welcome-mode)
    (prelude-welcome-refresh)))

(defconst my/welcome--fill-column 72
  "Column at which the module toggle buttons wrap.")

(defun my/welcome--insert-toggles ()
  "Insert the module toggle buttons, wrapped to `my/welcome--fill-column'."
  (let ((col 2))
    (insert "  ")
    (dolist (module my/gui-modules)
      (let* ((on (memq module my/terminal-extra-modules))
             (label (format "[%s %s]" (if on "x" " ") module))
             (width (1+ (length label))))
        ;; wrap before overflowing, but never leave a line empty
        (when (and (> col 2) (> (+ col width) my/welcome--fill-column))
          (insert "\n  ")
          (setq col 2))
        (insert-text-button
         label
         'action (lambda (_b) (my/terminal-toggle-module module))
         'help-echo (format "%s %s for terminal Emacs"
                            (if on "Disable" "Enable") module)
         'follow-link t)
        (insert " ")
        (setq col (+ col width))))
    (insert "\n")))

(defun my/welcome--insert-terminal-tier ()
  "Insert the terminal-tier section into the welcome buffer."
  (if (fboundp 'prelude-welcome--heading)
      (prelude-welcome--heading "Terminal tier")
    (insert "\n  " (propertize "Terminal tier" 'face 'bold) "\n"))
  (insert (propertize
           (if my/gui-p
               "  GUI frame -- every module below is already loaded here.\n  Toggling changes what `emacs -nw' loads.\n"
             "  Terminal frame -- only the ticked modules are loaded here.\n  The rest are skipped to keep `emacs -nw' fast.\n")
           'face 'font-lock-comment-face))
  (insert (propertize
           "  TAB / S-TAB to a button, RET toggles it.  Same thing from\n  anywhere: M-x my/terminal-toggle-module.  Enabling takes effect\n  at once; disabling needs a restart.\n\n"
           'face 'font-lock-comment-face))
  (my/welcome--insert-toggles)
  (insert (propertize
           "\n  eglot is always on: prelude-programming loads it, and C/C++ pick\n  it up via prelude-c in the always-on tier.\n"
           'face 'font-lock-comment-face)))

(defun my/welcome--insertion-point ()
  "Return where the terminal-tier section should go.
Just above the first of Prelude's own lower sections, so it lands
directly under \"Getting started\" rather than at the very bottom."
  (catch 'found
    (dolist (anchor '("\n  Recent files\n" "\n  Projects\n" "\n  Bookmarks\n"
                      "\n  Tip of the day\n" "\n  TAB/S-TAB"))
      (goto-char (point-min))
      (when (search-forward anchor nil t)
        (throw 'found (match-beginning 0))))
    (point-max)))

(defun my/welcome--augment (buf)
  "Insert the terminal-tier section into welcome buffer BUF."
  (when (buffer-live-p buf)
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (save-excursion
          (goto-char (my/welcome--insertion-point))
          (my/welcome--insert-terminal-tier)))))
  buf)

(with-eval-after-load 'prelude-welcome
  (advice-add 'prelude-welcome--render :filter-return #'my/welcome--augment))

(provide 'prelude-welcome-extras)
;;; prelude-welcome-extras.el ends here
