;; -*- coding: utf-8; lexical-binding: t; -*-

;=========================================================================================;
; Emacs Setup                                                                             ;
;-----------------------------------------------------------------------------------------;
;      init.el    Loads files performantly*, keeping the initial loading time short, by   ;
;                   skipping regex checks and lazy loading files                          ;
;        ux.el    Minor modes and window variables                                        ;
;   theming.el    Sets the theme, font, and modifies UI elements like the mode line       ;
;  packages.el    Tells Emacs what packages to download and install                       ;
;   folding.el    Custom solutions for code folding                                       ;
;  workflow.el    Shortcuts and functions                                                 ;
;   \-modes.el    Custom minor modes                                                      ;
;=========================================================================================;
;  *performantly is a real word that exists, yes                                          ;

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(setq load-prefer-newer t)
(defconst emacs_dir (file-name-as-directory user-emacs-directory)) ; .config/emacs
(defun load_init (pkg &optional maybe-disabled)
  (load (file-truename (format "%s/%s" emacs_dir pkg)) t t))

;; Backups and Autosaves go to folder in .config/emacs
(defconst backup_dir (concat emacs_dir "backups/"))
(setq backup-directory-alist `(("." . ,backup_dir))
      make-backup-files t)
(defconst autosave_dir (concat emacs_dir "autosaves/"))
(make-directory autosave_dir t)
(setq auto-save-file-name-transforms `((".*" ,autosave_dir t))
      auto-save-default t)


;; These load at runtime
(let* ((file-name-handler-alist nil))
    (load_init 'ux.el)
    (load_init 'theming.el)
    (load_init 'dressing.el)
    )

;; These lazy-load after init
(run-with-idle-timer
    0.1 nil
    (lambda ()
      (let* ((file-name-handler-alist nil))
    (load_init 'packages.el)
    (load_init 'workflow.el)
    (load_init 'workflow-modes.el)
    )))


;; GC Timer
(defun cleanup_gc ()
  (setq gc-cons-threshold  67108864)      ; 64M
  (setq gc-cons-percentage 0.1)           ; original value
  (garbage-collect))

(run-with-idle-timer 4 nil #'cleanup_gc)

(message "*** Emacs loaded in %s with %d garbage collections."
         (format "%.2f seconds"
         (float-time (time-subtract after-init-time before-init-time)))
         gcs-done)



; Credit and Thanks:
; https://github.com/redguardtoo/emacs.d

;;; End:
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("f6a9804d857f9b0c75e1045b8aba5bc1b976f69c5369440edce5eb49c9ed16cf" default))
 '(package-selected-packages
   '(all-the-icons all-the-icons-dired company dired-preview dumb-jump easysession eldoc-box format-all
                   git-modes ligature magit mason move-text multiple-cursors nerd-icons
                   nerd-icons-dired rainbow-mode rg rust-mode treesit-auto treesit-fold))
 '(qp-compile-animation 'pacman)
 '(qp-compile-rotation t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
