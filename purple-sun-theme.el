;;; purple-sun-theme.el --- african daisy purple sun --- -*- lexical-binding: t; no-byte-compile: t; -*-
;;
;; author: Miguel Cerqueira
;; warning: This file is not part of GNU Emacs, and is not under warranty.
;; version: This is a pre-release file. Do not submit bug reports for it.
;;

;;;###theme-autoload
(deftheme purple-sun "In Development.")
(setq font-lock-maximum-decoration t)

; ----------------------------------------- UI THEMING ----------------------------------------- ;

;; Draws an arrow on the right edge when line is truncated by truncate-lines
(define-fringe-bitmap 'custom-truncation-right
  [#b00001000
   #b00001100
   #b00001110
   #b11111111
   #b00001110
   #b00001100
   #b00001000])

;; Removes < on the left edge
(define-fringe-bitmap 'custom-truncation-left
  [#b00000000])

(setq-default fringe-indicator-alist
              (cons '(truncation custom-truncation-left custom-truncation-right)
                    (assq-delete-all 'truncation fringe-indicator-alist)))
(setq-default fringe-indicator-alist
              (cons '(truncation custom-truncation-left custom-truncation-right)
                    (assq-delete-all 'truncation
              fringe-indicator-alist)))

;; Removes $ at the left edge when truncated
;; You have to scroll right first anyway, so we know there's code before that anyway
(unless standard-display-table
  (setq standard-display-table (make-display-table)))
(set-display-table-slot standard-display-table 'truncation ?\s)


; ------------------------------------------- COLORS ------------------------------------------- ;

(require 'color)
(setq t-bg            "#0D1117"
      t-fg            "#EEE"
      t-all-ok        "OliveDrab2"
      t-warning       "DarkOrange1"
      t-error         "#F00"
      
      t-accent        "plum"
      t-border        "plum3"
      t-border-weak   "grey23"
      t-emphasis      "orchid1"
      t-deemphasis    "orchid4"
      t-ignore        "LavenderBlush4"
      t-highlight     "orange"
      t-link          "gold"
      
      c-docs          "LavenderBlush3"
      c-comment       "LavenderBlush4"
      c-string        "orange"
      c-keyword       c-string
      c-function      t-accent
      c-variable      t-fg
      c-builtin       t-accent
      c-type          t-accent
      c-constant      "tomato1"
      )

(setq t-bg-1 (color-lighten-name  t-bg 25)
      t-bg-2 (color-lighten-name  t-bg 50)
      t-bg-3 (color-lighten-name  t-bg 100)
      t-fg-1 (color-darken-name   t-fg 25)
      )


; ------------------------------------------- FACES -------------------------------------------- ;

;; custom faces
(custom-theme-set-faces 'purple-sun

;; Common
  `(default        ((t (:background, t-bg     :foreground, t-fg  ))))
  `(fringe         ((t (:background, t-bg        ))))
  `(cursor         ((t (:background, t-highlight ))))
  `(match          ((t (:background, t-bg-3   :foreground, t-highlight  ))))
  `(highlight      ((t (:background, t-bg-3   :foreground, t-highlight  ))))
  `(lazy-highlight ((t (:background, t-bg-3   :foreground, t-highlight  ))))
  `(region         ((t (:background, t-bg-3     ))))
  `(link           ((t (:foreground, t-link       :underline t))))
  `(link-visited   ((t (:foreground, t-ignore     :underline t :italic t))))

  `(hl-line                  ((t (:background, t-bg-2  :box, t-border-weak       :extend t))))
  `(match                    ((t (:background, t-bg-3  :foreground, t-highlight  :weight bold))))
  `(tooltip                  ((t (:foreground, t-fg-1  :background, t-bg-3))))
  `(vertical-border          ((t (:foreground, t-border ))))
  `(line-number              ((t (:foreground, t-fg  )))) 
  `(line-number-current-line ((t (:foreground, t-highlight  ))))
  `(query-replace            ((t (:background, t-bg-3 ))))

  `(success ((t (:foreground, t-all-ok))))
  `(warning ((t (:foreground, t-warning))))
  `(error   ((t (:foreground, t-error))))
  `(shadow  ((t (:foreground, t-ignore ))))
  `(button  ((t (:foreground, t-highlight   :underline t))))

  `(secondary-selection          ((t (:background unspecified  :foreground, t-deemphasis))))
  `(minibuffer-prompt            ((t (:foreground, t-highlight :weight bold ))))     ; ex: commands
  `(completions-common-part      ((t (:foreground, t-emphasis))))
  `(completions-first-difference ((t (:foreground, t-deemphasis))))

;; Code
  `(font-lock-comment-face       ((t (:foreground, c-comment    :background, t-bg-1   :italic t ))))
  `(font-lock-doc-face           ((t (:foreground, c-docs       :background, t-bg-1  ))))
  `(font-lock-doc-markup-face    ((t (:bold t  ))))
  `(font-lock-string-face        ((t (:foreground, c-string     ))))
  `(font-lock-keyword-face       ((t (:foreground, c-keyword    :weight bold))))
  `(font-lock-builtin-face       ((t (:foreground, c-builtin    ))))
  `(font-lock-function-name-face ((t (:foreground, c-function   :weight extra-bold))))
  `(font-lock-function-call-face ((t (:foreground, c-function   :weight extra-bold))))
  `(font-lock-variable-name-face ((t (:foreground, c-variable   ))))
  `(font-lock-variable-use-face  ((t (:foreground, c-variable   ))))
  `(font-lock-type-face          ((t (:foreground, c-type ))))
  `(font-lock-constant-face      ((t (:foreground, c-constant ))))
  `(font-lock-warning-face       ((t (:foreground, t-error ))))
  `(font-lock-negation-char-face ((t (:foreground, c-constant   :weight bold))))
  `(font-lock-preprocessor-face  ((t (:foreground, t-fg ))))
  
  `(font-lock-regexp-face               ((t (:foreground, t-fg ))))
  `(font-lock-regexp-grouping-construct ((t (:foreground, t-ignore ))))
  `(font-lock-regexp-grouping-backslash ((t (:foreground, t-link ))))

  `(show-paren-match    ((t (:foreground, t-bg  :background, t-fg  ))))
  `(show-paren-mismatch ((t (:foreground, t-bg  :background, t-error  ))))
  `(escape-glyph        ((t (:foreground, t-highlight  :weight bold  ))))
  `(homoglyph           ((t (:foreground, t-warning ))))


;; Mode-line
  `(mode-line           ((t (:foreground, t-fg          :background, t-bg      :box, t-border))))                  ; color of text and background of the bar
  `(mode-line-inactive  ((t (:foreground, t-fg-1        :background, t-bg      :box, t-border-weak))))             ; when there are multiple windows
  `(mode-line-buffer-id ((t (:foreground, t-fg          :weight bold           :distant-foreground, t-fg-1))))     ; name of the buffer
  `(mode-line-emphasis  ((t (:foreground, t-emphasis    :weight bold))))                                           ; features that can't be selected
  `(mode-line-highlight ((t (:foreground, t-highlight   :background unspecified))))                                ; features that can   be selected

;; Dired
  `(dired-directory      ((t (:foreground, t-fg          :weight bold))))      ; color of folder names
  `(dired-ignored        ((t (:foreground, t-ignore      ))))                  ; color of hidden / ignored
  `(dired-warning        ((t (:foreground, t-warning     :weight bold))))      ; bad news
  `(dired-flagged        ((t (:foreground, t-error       :weight bold))))      ; flagged for deletion
  `(dired-header         ((t (:foreground, t-accent      :weight bold))))      ; color of buffer name
  `(dired-mark           ((t (:foreground, t-highlight   :weight bold))))      ; color of mark indicator
  `(dired-marked         ((t (:foreground, t-highlight   :weight bold))))      ; marked files
  `(dired-perm-write     ((t (:foreground, t-emphasis    :underline t))))      ; permissions
  `(dired-special        ((t (:foreground, t-accent      ))))                  ; sockets, pipes and devices
  `(dired-set-id         ((t (:foreground, t-deemphasis  ))))                  ; setuid
  `(dired-symlink        ((t (:foreground, t-link        :underline t))))      ; system links
  `(dired-broken-symlink ((t (:foreground, t-ignore      :weight bold))))      ; dead links

;; isearch
  `(isearch         ((t (:foreground, t-highlight  :background, t-bg-3 ))))
  `(isearch-fail    ((t (:foreground, t-deemphasis :background, t-bg-3 ))))
  `(isearch-group-1 ((t (:foreground, t-emphasis   :background, t-bg-3 ))))
  `(isearch-group-2 ((t (:foreground, t-accent     :background, t-bg-3 ))))

;; Company
  `(company-tooltip           ((t (:foreground, t-ignore     :background, t-bg  ))))
  `(company-tooltip-common    ((t (:foreground, t-highlight  :background unspecified  ))))
  `(company-tooltip-selection ((t (:foreground, t-fg         :background, t-bg-2  ))))
  `(company-scrollbar-fg      ((t (:background, t-accent )))) 
  `(company-scrollbar-bg      ((t (:background, t-bg-3   ))))

;; CSS
  `(css-proprietary-property ((t (:foreground, t-accent))))
  `(css-property             ((t (:foreground, t-fg))))
  `(css-selector             ((t (:foreground, t-highlight))))

;; Treemacs
  `(treemacs-root-face                ((t (:foreground, t-highlight  :weight bold  :underline t  :height 140))))
  `(treemacs-directory-face           ((t (:foreground, t-ignore   ))))  
  `(treemacs-directory-collapsed-face ((t (:foreground, t-ignore   ))))
  `(treemacs-git-unmodified-face      ((t (:foreground, t-fg       ))))
  `(treemacs-git-modified-face        ((t (:foreground, t-accent  :underline t  ))))
  `(treemacs-git-renamed-face         ((t (:foreground, t-accent   ))))
  `(treemacs-git-added-face           ((t (:foreground, t-highlight))))
  `(treemacs-git-ignored-face         ((t (:foreground, t-bg-3     ))))
  `(treemacs-git-untracked-face       ((t (:foreground, t-warning  ))))
  `(treemacs-git-conflict-face        ((t (:foreground, t-error    ))))

;; Tabs (how many damn tabs are there?)
  `(tab-bar              ((t (:background, t-bg ))))
  `(tab-bar-tab          ((t (:background, t-bg-2  :foreground, t-fg
                              :underline (:color, t-accent :position t )))))
  `(tab-bar-tab-inactive ((t (:background, t-bg    :foreground, t-ignore  ))))

  `(tab-line              ((t (:background, t-bg-3  ))))
  `(tab-line-tab          ((t (:background, t-bg-2  :foreground, t-fg  ))))
  `(tab-line-tab-inactive ((t (:background, t-bg-3  :foreground, t-ignore ))))
  `(tab-line-highlight    ((t (:background, t-bg-2  :foreground, t-highlight ))))
  `(tab-line-tab-current  ((t (:background, t-bg-2  :foreground, t-fg  ))))

  `(centaur-tabs-default                   ((t (:background, t-bg ))))
  `(centaur-tabs-selected                  ((t (:background, t-bg-3 :foreground, t-fg  ))))
  `(centaur-tabs-unselected                ((t (:background, t-bg   :foreground, t-ignore  ))))
  `(centaur-tabs-active-bar-face           ((t (:background, t-accent ))))
  `(centaur-tabs-close-mouse-face          ((t (:foreground, t-highlight ))))
  `(centaur-tabs-name-mouse-face           ((t (:foreground, t-accent ))))

;; hi-lock
  `(hi-yellow     ((t (:background "orange"         :foreground, t-bg  ))))
  `(hi-pink       ((t (:background "plum"           :foreground, t-bg  ))))
  `(hi-green      ((t (:background "OliveDrab2"     :foreground, t-bg  ))))
  `(hi-blue       ((t (:background "sky blue"       :foreground, t-bg  ))))
  `(hi-salmon     ((t (:background "tomato1"        :foreground, t-bg  ))))
  `(hi-aquamarine ((t (:background "LavenderBlush3" :foreground, t-bg  ))))
  `(hi-black-b    ((t (:background "LavenderBlush4" :foreground, t-bg  ))))
  `(hi-blue-b     ((t (:background "gold"           :foreground, t-bg  ))))
  `(hi-green-b    ((t (:background "orchid"         :foreground, t-bg    ))))
  `(hi-red-b      ((t (:background "#F00"           :foreground, t-bg  ))))
  `(hi-black-hb   ((t (:background "#FFF"           :foreground, t-bg   ))))

;; Eldoc-Box
  `(eldoc-box-border             ((t (:background, t-accent ))))
  `(eldoc-box-body               ((t (:background, t-bg-2  :foreground, t-fg   ))))
  `(eldoc-box-markdown-separator ((t (:foreground, t-highlight   ))))
  

;; end custom faces
)


(provide-theme 'purple-sun)
;;; purple-sun-theme.el ends here
