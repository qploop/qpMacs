;; -*- coding: utf-8; lexical-binding: t; -*-

(load-theme 'purple-sun t)

; --------------------------------------------- UI --------------------------------------------- ;

;; Gutter padding (line numbers)
(setq-default line-prefix (propertize " " 'display '(space :width 1)))
(setq-default wrap-prefix (propertize " " 'display '(space :width 1)))

;; Changing the title from GNU Emacs at [system]
(setq frame-title-format "%b")

;; Optional Transparency
(set-frame-parameter nil           'alpha-background   100)
(add-to-list 'default-frame-alist '(alpha-background . 100))


;=============================================
;  Mode Line
;=============================================
(setq display-time-format "%H:%M"
      display-time-default-load-average nil)
(display-time-mode 1)

(defface qp--custom-modeline
  '((t :inherit font-lock-comment-face :inverse-video t :weight bold))
  "Face for the mode line major mode indicator.")

(defun qp--clean-mode-name()
  "Cleans C// mode and C++// Mode."
  (replace-regexp-in-string "/.*\\'" "" (format-mode-line mode-name)))

(defun qp--locked-by-other-p()
  "Non-nil if the visited file is locked by another user or Emacs session."
  (let ((file (buffer-file-name (or (buffer-base-buffer) (current-buffer)))))
    (and file
         (not (file-remote-p file))   ; avoid slow TRAMP checks on every redisplay
         (stringp (file-locked-p file)))))

;---------------------------------------
; Compile Animation

(defcustom qp-compile-animation-presets
  '((loading   . ["▰▱▱▱" "▱▰▱▱" "▱▱▰▱" "▱▱▱▰"])
    (braille   . ["⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"])
    (moon      . ["🌑" "🌒" "🌓" "🌔" "🌕" "🌖" "🌗" "🌘"])
    (raining   . ["`' ☂ .|"  ".| ☂' ."  "' .☂| `"  "|. ☂ '."  "'| ☂`.'"  ". `☂| |"])
    (pacman    . ["ᗧ·····" " ᗧ····" "  ᗧ···" "   ᗧ··" "    ᗧ·"  "     ᗧ"])
   )
  "Named animation presets for the compilation indicator."
  :type '(alist :key-type symbol :value-type (vector string))
  :group 'mode-line)

(defcustom qp-compile-interval 0.30
  "Seconds between compile animation frames."
  :type 'number
  :group 'mode-line)

(defvar qp--compile-frames (alist-get 'loading qp-compile-animation-presets) "Active animation frames for the compilation indicator.")
(defvar qp--compile-frame 0)
(defvar qp--compile-timer nil)

(defun qp--compile-apply-animation (symbol value)
  (set-default symbol value)
  (let ((frames (if (symbolp value)
                    (alist-get value qp-compile-animation-presets)
                  (vconcat value))))
    (setq qp--compile-frames
          (if (and frames (> (length frames) 0))
              frames
            (alist-get 'loading qp-compile-animation-presets))))
  (setq qp--compile-frame 0))

(defcustom qp-compile-animation 'loading
  "Active compile animation."
  :type '(choice (symbol :tag "Preset name")
                 (repeat :tag "Custom frames" string))
  :set #'qp--compile-apply-animation
  :group 'mode-line)

(defun qp-config-compile-animation (animation)
  (interactive
   (list (intern (completing-read "Animation: "
                                  (mapcar (lambda (p) (symbol-name (car p)))
                                          qp-compile-animation-presets)
                                  nil t))))
  (customize-save-variable 'qp-compile-animation animation))

(defun qp--compile-glyph()
  (if (bound-and-true-p compilation-in-progress)
      (aref qp--compile-frames (mod qp--compile-frame (length qp--compile-frames)))
    ""))

(defun qp--compile-rotate()
  "Advance `qp-compile-animation' to the next preset, wrapping around."
  (let* ((keys (mapcar #'car qp-compile-animation-presets)))
    (when keys
      (let* ((n (length keys))
             (idx (let ((i 0) (found nil))
                    (while (and (null found) (< i n))
                      (when (eq qp-compile-animation (nth i keys))
                        (setq found i))
                      (setq i (1+ i)))
                    found))
             (next (nth (mod (1+ (or idx -1)) n) keys)))
        (qp--compile-apply-animation 'qp-compile-animation next)))))

(defun qp--compile-stop()
  (when qp--compile-timer
    (cancel-timer qp--compile-timer)
    (setq qp--compile-timer nil))
  (setq qp--compile-frame 0)
  (qp--compile-rotate)
  (force-mode-line-update t))

(defun qp--compile-tick()
  (if (bound-and-true-p compilation-in-progress)
      (progn
        (setq qp--compile-frame
              (mod (1+ qp--compile-frame) (length qp--compile-frames)))
        (force-mode-line-update t))
    (qp--compile-stop)))

(defun qp--compile-start(&rest _)
  (unless qp--compile-timer
    (setq qp--compile-timer
          (run-with-timer qp-compile-interval qp-compile-interval
                          #'qp--compile-tick))))

(add-hook 'compilation-start-hook #'qp--compile-start)


;---------------------------------------
; Glyphs
; https://unicodes.jessetane.com/    ☂  ꕤ  ꗃ

(defun qp--state-glyph()
  (cond ((derived-mode-p 'dired-mode 'wdired-mode) "")
        ((eq major-mode 'compilation-mode)
         (if compilation-in-progress "" " ☘"))
        (buffer-read-only " ꕤ")
        ((qp--locked-by-other-p) " ꗃ")
        ((and (buffer-base-buffer) (buffer-modified-p)) " ⎇")
        ((buffer-modified-p) " ✦")
        (t " ✧")))

(defun qp--dired-glyph()
  (cond ((derived-mode-p 'wdired-mode) "✎")
        ((derived-mode-p 'dired-mode)  "▤")
        (t "")))

(defun qp--eglot-glyph()
  (if (and (fboundp 'eglot-managed-p) (eglot-managed-p)) "⧉" ""))

(defun qp--treesit-glyph()
  (if (and (fboundp 'treesit-parser-list) (treesit-parser-list)) "⋔" ""))

(defun qp--extra-glyphs()
  "Inserted alongside state glyph."
  (let ((glyphs (seq-remove #'string-empty-p
                            (list (qp--compile-glyph)
                                  (qp--eglot-glyph)
                                  (qp--treesit-glyph)
                                  (qp--dired-glyph)))))
    (if glyphs (concat " " (string-join glyphs " ")) "")))

;---------------------------------------
; Mode Line Display

(setq-default mode-line-format
 '(" %e" " %b "
   mode-line-format-right-align
   (:propertize display-time-string face bold)
   "  "
   (:eval (let ((text (concat (qp--state-glyph)
                              (qp--extra-glyphs)
                              " " (qp--clean-mode-name) "  ")))
            (when (mode-line-window-selected-p)
              (add-face-text-property 0 (length text) 'qp--custom-modeline t text))
            text))))


; -------------------------------------------- FONTS ------------------------------------------- ;

(defvar qp-fonts '(
    (iosevka   :font "Iosevka Slab"   :height 115)
    (fira      :font "Fira Code"      :height 115)
    ))

;=============================================
;  Font Switching
;=============================================

(defcustom qp-current-font 'nil 
  "Tracks font currently in use."
  :type 'symbol  
  :group 'faces)

(defun qp-font-apply (saved-font &optional save)
  "Applies and saves font choice."
  (let ((custom-font (cdr (assq saved-font qp-fonts))))
    (unless (and custom-font (find-font (font-spec :name (plist-get custom-font :font))))
      (setq saved-font (caar qp-fonts)
            custom-font (cdar qp-fonts)))
    (apply #'set-face-attribute 'default nil custom-font)
    (setq qp-current-font saved-font)
    (when save
      (customize-save-variable 'qp-current-font saved-font))
    (message "Font set to %s" saved-font)))

(defun qp-config-font-cycle()
  "Cycle to the next font in `qp-fonts'"
  (interactive)
  (let* ((keys (mapcar #'car qp-fonts))
         (next (or (cadr (memq qp-current-font keys))
                   (car keys))))
    (qp-font-apply next t)))

(defun qp-config-set-font()
  "Prompt for fonts present in `qp-fonts'"
  (interactive)
  (let ((choice (minibuffer-with-setup-hook #'minibuffer-completion-help
                  (completing-read
                   "Font: "
                   (mapcar (lambda (entry) (symbol-name (car entry))) qp-fonts)
                   nil t))))
    (qp-font-apply (intern choice) t)))

;; Apply the saved font at startup
(add-hook 'after-init-hook (lambda () (qp-font-apply qp-current-font)))


;=============================================
;  Ligatures
;=============================================

(unless (package-installed-p 'ligature)
   (package-refresh-contents)
   (package-install 'ligature))

(ligature-set-ligatures 't '("www"))
(ligature-set-ligatures 'eww-mode '("ff" "fi" "ffi"))
(ligature-set-ligatures 'prog-mode
    '("|||>" "<|||" "<==>" "<!--" "####" "~~>" "***" "||=" "||>"
	  ":::" "::=" "=:=" "===" "==>" "=!=" "=>>" "=<<" "=/=" "!=="
	  "!!." ">=>" ">>=" ">>>" ">>-" ">->" "->>" "-->" "---" "-<<"
	  "<~~" "<~>" "<*>" "<||" "<|>" "<$>" "<==" "<=>" "<=<" "<->"
	  "<--" "<-<" "<<=" "<<-" "<<<" "<+>" "</>" "###" "#_(" "..<"
	  "..." "+++" "/==" "///" "_|_" "www" "&&" "^=" "~~" "~@" "~="
	  "~>" "~-" "**" "*>" "*/" "||" "|}" "|]" "|=" "|>" "|-" "{|"
	  "[|" "]#" "::" ":=" ":>" ":<" "$>" "==" "=>" "!=" "!!" ">:"
	  ">=" ">>" ">-" "-~" "-|" "->" "--" "-<" "<~" "<*" "<|" "<:"
	  "<$" "<=" "<>" "<-" "<<" "<+" "</" "#{" "#[" "#:" "#=" "#!"
	  "##" "#(" "#?" "#_" "%%" ".=" ".-" ".." ".?" "+>" "++" "?:"
	  "?=" "?." "??" ";;" "/*" "/=" "/>" "//" "__" "~~" "(*" "*)"
	  "\\\\" "://"))
(global-ligature-mode t)



;; theming.el ends here
