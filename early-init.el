;; -*- coding: utf-8; lexical-binding: t; -*-


;; Prevents flickers on boot
(setq default-frame-alist '((background-color . "#0d1117")
                            (ns-appearance . dark)
                            (ns-transparent-titlebar . t))
      inhibit-startup-message t
      initial-frame-alist default-frame-alist
      frame-inhibit-implied-resize t)
(set-face-attribute 'fringe nil :background "#0d1117")
(menu-bar-mode   -1)
(tool-bar-mode   -1)
(scroll-bar-mode -1)


;; https://github.com/redguardtoo/emacs.d
(when (or (featurep 'esup-child)
          (fboundp 'profile-dotemacs)
          (daemonp)
          (boundp 'startup-now)
          noninteractive)
  (setq package-enable-at-startup nil))


;; Garbage Collector
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6) 

;; (setq gc-cons-threshold (* 50 1024 1024)) ;; 50 MB
;; (add-hook 'emacs-startup-hook
;;           (lambda ()
;;             (setq gc-cons-threshold (* 16 1024 1024)
;;                   gc-cons-percentage 0.1)))        



(provide 'early_init)
;;; early-init.el ends here
