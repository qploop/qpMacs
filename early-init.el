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


(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.3
      read-process-output-max (* 10 1024 1024))
(defun user--setup-gc()
  (setq gc-cons-threshold (* 100 1024 1024)
        gc-cons-percentage 0.3
        read-process-output-max (* 10 1024 1024)   
        inhibit-compacting-font-caches t))
(add-hook 'after-init-hook #'user--setup-gc)



(provide 'early_init)
;;; early-init.el ends here
