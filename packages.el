;; -*- coding: utf-8; lexical-binding: t; -*-

;; Move Text
(use-package move-text
  :ensure t
  :config
  (move-text-default-bindings))    ; Alt + ↑ || Alt + ↓


;; Multiple Cursors
(use-package multiple-cursors
  :ensure t)


;; Magit
(use-package magit
  :ensure t)
(use-package git-modes
  :ensure t)


;; Treemacs
(use-package treemacs
  :ensure t)
(use-package treemacs-magit
  :after (treemacs magit)
  :ensure t)
(use-package treemacs-tab-bar
  :after treemacs
  :ensure t)
(use-package treemacs-icons-dired
  :ensure t
  :after (treemacs dired)
  :hook (dired-mode . treemacs-icons-dired-enable-once))


;; EasySession
(use-package easysession
  :ensure t
  :bind (("C-c s s" . easysession-save)
         ("C-c s l" . easysession-switch-to)))


;; EMACS EXPERIMENTAL v31
;; https://rahuljuliato.com/posts/markdown-ts-mode-emacs-31
;; (use-package markdown-ts-mode
;;   :ensure nil
;;   :mode ("\\.md\\'" "\\.mdx\\'" "\\.markdown\\'")
;;   :config
;;   (require 'markdown-ts-mode-x))


; ------------------------------------------- SYNTAX ------------------------------------------- ;

;; Rust
(use-package rust-mode
  :ensure t)


;; Company - text completion
(use-package company
  :ensure t
  :init
  (global-company-mode 1)
  :custom
  (company-idle-delay 0.2)
  (company-minimum-prefix-length 2))


;; Rainbow Mode
(use-package rainbow-mode
  :ensure t)


;==============================
;  LSP and Documentation
;==============================

(setq eglot-code-action-indications nil)

;; Package Installer
(use-package mason
  :ensure t)


;; RipGrep
;; The only Rust project ever without the "blazingly fast" tagline, worth noting
(use-package rg
  :ensure t)


;; Dump-jumb   see end of file ↓
(use-package dumb-jump
  :ensure t)


;; Eldoc UI
(use-package eldoc-box
  :ensure t)
(global-set-key (kbd "C-c d")               'eldoc-box-help-at-point)


;=======================================
;  Treesitter
;=======================================

(use-package treesit-fold
  :ensure t)

(use-package treesit-auto
  :ensure t
  :custom
  (treesit-auto-install t)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))
(setq treesit-font-lock-level 4)

(setq treesit-language-source-alist
      '((bash       "https://github.com/tree-sitter/tree-sitter-bash")
        (c          "https://github.com/tree-sitter/tree-sitter-c")
        (c-sharp    "https://github.com/tree-sitter/tree-sitter-c-sharp")
        (cmake      "https://github.com/uyha/tree-sitter-cmake")
        (cpp        "https://github.com/tree-sitter/tree-sitter-cpp")
        (css        "https://github.com/tree-sitter/tree-sitter-css")
        (dockerfile "https://github.com/camdencheek/tree-sitter-dockerfile")
        (elisp      "https://github.com/Wilfred/tree-sitter-elisp")
        (go         "https://github.com/tree-sitter/tree-sitter-go")
        (gomod      "https://github.com/camdencheek/tree-sitter-go-mod")
        (html       "https://github.com/tree-sitter/tree-sitter-html")
        (java       "https://github.com/tree-sitter/tree-sitter-java")
        (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
        (json       "https://github.com/tree-sitter/tree-sitter-json")
        (kotlin     "https://github.com/fwcd/tree-sitter-kotlin")
        (lua        "https://github.com/tree-sitter-grammars/tree-sitter-lua")
        (make       "https://github.com/tree-sitter-grammars/tree-sitter-make")
        (markdown   "https://github.com/tree-sitter-grammars/tree-sitter-markdown" "split_parser" "tree-sitter-markdown/src")
        (markdown-inline "https://github.com/tree-sitter-grammars/tree-sitter-markdown" "split_parser" "tree-sitter-markdown-inline/src")
        (php        "https://github.com/tree-sitter/tree-sitter-php" "master" "php/src")
        (python     "https://github.com/tree-sitter/tree-sitter-python")
        (ruby       "https://github.com/tree-sitter/tree-sitter-ruby")
        (rust       "https://github.com/tree-sitter/tree-sitter-rust")
        (scala      "https://github.com/tree-sitter/tree-sitter-scala")
        (toml       "https://github.com/tree-sitter-grammars/tree-sitter-toml")
        (tsx        "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
        (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
        (yaml       "https://github.com/tree-sitter-grammars/tree-sitter-yaml")))

(dolist (lang (mapcar #'car treesit-language-source-alist))
  (unless (treesit-language-available-p lang)
    (treesit-install-language-grammar lang)))


;---------------------------------------
; Dumb-jump eglot patch
;   Using Eglot, xref overwrites dumb-jump and can sometimes fail to catch a definition
;   Under these circumstances, we need to dumb eglot down
;   eglot-stay-out-of   might also work   

(use-package dumb-jump
  :ensure t
  :config
  (setq dumb-jump-prefer-searcher 'rg)
  (add-hook 'xref-backend-functions #'dumb-jump-xref-activate 90))
(setq dumb-jump-default-project "~/projects")
(setq dumb-jump-rust-search-dependencies t)

(defun patch--dumb-eglot(origin backend id)
  (or (ignore-errors (funcall origin backend id))
      (and (eq backend 'eglot)
           (ignore-errors
             (xref-backend-definitions
              'dumb-jump (xref-backend-identifier-at-point 'dumb-jump))))))
(advice-add 'xref-backend-definitions :around #'patch--dumb-eglot)



(provide 'packages)
;;; packages.el ends here
