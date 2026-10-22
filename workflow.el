
;; -*- coding: utf-8; lexical-binding: t; -*-

;; Project.el
(setq project-vc-extra-root-markers '(".project" "package.json" "Cargo.toml" "go.mod"))
(project-remember-projects-under "~/projects" t)

;=======================================
;  Shortcuts
;=======================================

(global-set-key (kbd "C-<left>")  (lambda () (interactive) (qp-symbol-jump -1)))
(global-set-key (kbd "C-<right>") (lambda () (interactive) (qp-symbol-jump  1)))

(global-set-key (kbd "C-,")               'qp-duplicate-line)
(global-set-key (kbd "C-c c")             'qp-comment-out)
(global-set-key (kbd "C-c t")             'qp-symbol-transform)

(global-set-key (kbd "C-c h h")           'qp-highlight)
(global-set-key (kbd "C-c h c")           'qp-highlight-clear)

(global-set-key (kbd "C-c w b")           'qp-write-block)
(global-set-key (kbd "C-c w s")           'qp-write-separator)
(global-set-key (kbd "C-c w d")           'qp-write-doc)
(global-set-key (kbd "C-c w c")           'qp-write-comment)

(global-set-key (kbd "C-z")               'undo)
(global-set-key (kbd "C-S-z")             'undo-redo)
(global-set-key (kbd "C-<")               'tab-new)
(global-set-key (kbd "C->")               'tab-close)
(global-set-key (kbd "C-<print>")         'overwrite-mode)

; Multiple Cursors
(when (package-installed-p 'multiple-cursors)
    (global-set-key (kbd "C-.")           'mc/mark-all-like-this)
    (global-set-key (kbd "C--")           'mc/edit-lines)
    (global-set-key (kbd "C-d")           'mc/mark-next-like-this)      ; vscode like
    (global-set-key (kbd "C-S-d")         'mc/mark-previous-like-this)) ;     //

; Magit
(when (package-installed-p 'magit)
    (global-set-key (kbd "C-c m s")       'magit-status)
    (global-set-key (kbd "C-c m l")       'magit-log))

; TreeMacs
(when (package-installed-p 'treemacs)
    (global-set-key (kbd "M-o")           'treemacs))


;=======================================
;  Easysession
;=======================================

(add-hook 'easysession-before--hook #'easysession-reset) ; Kills all buffers on load
(setq easysession-fontify t)
(setq enable-local-variables :safe)


; ----------------------------------------- FUNCTIONS ------------------------------------------ ;

;=======================================
;  Utility Functions
;=======================================

(defun qp-duplicate-line()
    "Duplicate current line, adjusts cursor position."
    (interactive)
    (let ((column (- (point) (point-at-bol)))
        (line (let ((s (thing-at-point 'line t)))
                (if s (string-remove-suffix "\n" s) ""))))
        (move-end-of-line 1)
        (newline)
        (insert line)
        (move-beginning-of-line 1)
        (forward-char column)))


(defun qp-symbol-jump(direction)
  "Jumps to next instance of a symbol at cursor. CTRL → or CTRL ←"
  (interactive "p")
  (let* ((bounds (bounds-of-thing-at-point 'symbol))
         (symbol (and bounds
                      (buffer-substring-no-properties (car bounds) (cdr bounds)))))
    (if (not symbol)
        (message "No symbol at point")
      (let ((regexp (concat "\\_<" (regexp-quote symbol) "\\_>"))
            (backward (< direction 0))
            (start (point)))
        ;; Step out doesn't jump to itself
        (goto-char (if backward (car bounds) (cdr bounds)))
        (if (funcall (if backward #'re-search-backward #'re-search-forward)
                     regexp nil t)
            (goto-char (match-beginning 0))
          (goto-char start)
          (message "No %s occurrence of '%s'"
                   (if backward "previous" "forward")
                   symbol))))))


(defun qp-symbol-transform()
  "Replace all occurrences of the symbol at point with an edited string. Case-sensitive."
  (interactive)
  (let* ((old (or (thing-at-point 'symbol t)
                  (user-error "No symbol at point")))
         (new (read-string (format "Replace \"%s\" with: " old) old))
         (regexp (concat "\\_<" (regexp-quote old) "\\_>"))
         (case-fold-search nil)
         (count 0))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward regexp nil t)
        (replace-match new t t)
        (setq count (1+ count))))
    (message "Replaced %d occurrence(s) of \"%s\"" count old)))


(defun qp-exit-buffer-no-prompt()
  "Kills current buffer without prompting for save."
  (interactive)
  (set-buffer-modified-p nil)
  (kill-buffer (current-buffer)))
(global-set-key (kbd "C-x k") #'qp-exit-buffer-no-prompt)


;=======================================
;  Comment Functions
;=======================================

(defun qp-comment-out()
  "Places a line, or a selected region, under a comment. 
   Uncomments a line, selected region, or contiguous commented lines."
  (interactive)
  (let* ((c-line-p (derived-mode-p 'c-mode))
         (comment-start (if c-line-p "// " comment-start))
         (comment-end   (if c-line-p "" comment-end)))
    (cond
     ((use-region-p)
      (let* ((rbeg (region-beginning))
             (rend (region-end))
             (beg (save-excursion
                    (goto-char rbeg)
                    (line-beginning-position)))
             (end (save-excursion
                    (goto-char rend)
                    (if (and (bolp) (> rend rbeg))
                        (line-end-position 0)
                      (line-end-position))))
             (comment-empty-lines t))
        (comment-or-uncomment-region beg end)))
     ((qp--is-comment?)
      (let ((beg (line-beginning-position))
            (end (line-end-position)))
        (save-excursion            ; ↓ returns 0 on non empty line
          (while (and (zerop (forward-line -1)) (qp--is-comment?))
            (setq beg (line-beginning-position))))
        (save-excursion
          (while (and (zerop (forward-line 1)) (qp--is-comment?))
            (setq end (line-end-position))))
        (uncomment-region beg end)))
     (t (comment-line 1)
        (forward-line -1)))))

(defun qp--is-comment?()
  "Checks if line is comment text."
  (save-excursion
    (back-to-indentation)
    (and (not (eolp))
         (let* ((pos (point))
                (eol (line-end-position))
                (state (syntax-ppss (min eol (+ pos 2))))
                (start (nth 8 state)))
           (and (nth 4 state)  ;  4 == inside a comment
                start
                (<= start pos)
                (progn
                  ;; check if comment reaches the end, for */ cases
                  (goto-char start)
                  (or (not (forward-comment 1))
                      (>= (point) eol))))))))


;=======================================
;  Write Functions
;=======================================
(defvar terminal-width 98)
(defvar line-width 39)
(defvar separator-upcase? t)

(defun qp-write-comment()
  "Prepares an important comment."
  (interactive)
  (let* ((start (point))
         (prefix (qp--write-get-prefix))
         (rule (make-string line-width ?-))
         (snippet (concat prefix rule "\n"
                          prefix " qp: \n"
                          )))
    (insert snippet)
    (goto-char start)
    (search-forward ": ")))


(defun qp-write-block(&optional text)
  "Inserts a styled comment, intended to describe a block of functions or classes that will follow it. Takes selected text, or a prompt."
  (interactive)
  (let* ((title  (qp--write-title text))
         (prefix (qp--write-get-prefix))
         (rule   (make-string line-width ?=)))
    (insert prefix rule "\n"
            prefix "  "  title "\n"
            prefix rule "\n")))


(defun qp-write-doc(&optional text)
  "Inserts a styled documentation comment, intended to describe the file. Takes selected text, or a prompt."
  (interactive)
  (let* ((title (qp--write-title text))
         (left  (string-trim (qp--write-get-prefix)))
         (right left)
         (inner (- terminal-width (length left) (length right)))
         (rule  (lambda (ch)
                  (concat left (make-string inner ch) right)))
         (row   (lambda (text)
                  (let ((s (concat " " text)))
                    (concat left s
                            (make-string (max 0 (- inner (length s))) ?\s)
                            right))))
         empty-pos)
    (insert (funcall rule ?=) "\n")
    (insert (funcall row title) "\n")
    (insert (funcall rule ?-) "\n")
    (setq empty-pos (+ (point) (length left) 1))
    (insert (funcall row "") "\n")
    (insert (funcall rule ?=) "\n")
    (goto-char empty-pos)))


(defun qp-write-separator(&optional text)
  "Inserts a centred separator, intended to visually divide a page. Takes selected text, or a prompt."
  (interactive)
  (let* ((title (qp--write-title text))
         (title (if separator-upcase? (upcase title) title))
         (left  (string-trim (qp--write-get-prefix)))
         (right left)
         ;; "<left> <dashes> <title> <dashes> <right>" -> 4 spaces of padding
         (fixed (+ (length left) (length right) (length title) 4))
         (dashes (max 2 (- terminal-width fixed)))
         (dl (/ dashes 2))
         (dr (- dashes dl)))
    (insert left " "
            (make-string dl ?-)
            " " title " "
            (make-string dr ?-)
            " " right)
    (unless (eolp) (insert "\n"))))


;---------------------------------------
;  helper functions

(defun qp--write-get-prefix()
  (or (car (seq-find (lambda (entry)
                       (apply #'derived-mode-p (cdr entry)))
                     qp--comment-prefix))
      "// "))

(defun qp--write-title(&optional text)
  (let ((raw (cond (text text)
                   ((use-region-p)
                    (prog1 (buffer-substring-no-properties
                            (region-beginning) (region-end))
                      (delete-region (region-beginning) (region-end))))
                   (t (read-string "Title: ")))))
    (string-trim (replace-regexp-in-string "[ \t\n]+" " " raw))))

(defvar qp--comment-prefix
  '(("#"   python-mode python-ts-mode
           ruby-mode ruby-ts-mode enh-ruby-mode
           sh-mode bash-ts-mode conf-mode yaml-mode yaml-ts-mode
           toml-ts-mode makefile-mode perl-mode cperl-mode
           r-mode ess-r-mode nix-mode dockerfile-mode)
    (";"   emacs-lisp-mode lisp-mode lisp-interaction-mode
           scheme-mode clojure-mode asm-mode ini-mode)
    ("--"  lua-mode sql-mode haskell-mode elm-mode ada-mode)
    ("%"   latex-mode LaTeX-mode tex-mode erlang-mode matlab-mode)
    ("\" " vimrc-mode))
"Fallback: //")



;=======================================
;  Search Functions
;=======================================

; Credit to: 
; https://blog.chmouel.com/posts/emacs-isearch/

;; isearch -> type -> CTRL + O triggers occur
(use-package isearch
  :ensure nil
  :defer t
  :config
  (defun chmouel-occur-from-isearch ()
    (interactive)
    (let ((query (if isearch-regexp
               isearch-string
             (regexp-quote isearch-string))))
      (isearch-update-ring isearch-string isearch-regexp)
      (let (search-nonincremental-instead)
        (ignore-errors (isearch-done t t)))
      (occur query)))
  :bind
  (:map isearch-mode-map
        ("C-o" . chmouel-occur-from-isearch)))

;; Auto focuses from isearch
(defun chmouel-select-window (window &rest _)
  "Select WINDOW for display-buffer-alist"
  (select-window window))
(setq display-buffer-alist
      '(((or . ((derived-mode . occur-mode)))
         (display-buffer-reuse-mode-window display-buffer-at-bottom)
         (body-function . chmouel-select-window)
         (dedicated . t)
         (preserve-size . (t . t)))))

;; Pressing enter on occur line closes the 'occur' window
(defun qp--occur-goto-and-close()
  (interactive)
  (let ((occur-win (selected-window)))
    (occur-mode-goto-occurrence)
    (when (and (window-live-p occur-win)
               (not (eq occur-win (selected-window)))
               (not (one-window-p t)))
      (delete-window occur-win))))
(with-eval-after-load 'replace
  (define-key occur-mode-map (kbd "RET") #'qp--occur-goto-and-close))

;; Fill isearch with string in region, enables edit mode in mini-buffer
(defun qp--isearch-region-then-edit (orig-fn forward &rest args)
  (if (not (use-region-p))
      (apply orig-fn forward args)
    (isearch-update-ring (buffer-substring-no-properties (mark) (point)))
    (deactivate-mark)
    (apply orig-fn forward args)
    (when forward (goto-char (mark)))
    (isearch-repeat (if forward 'forward 'backward))
    ;; C-o in the minibuffer: exit, then replay C-o so isearch runs 'occur'
    (minibuffer-with-setup-hook
        (lambda ()
          (use-local-map
           (make-composed-keymap
            (define-keymap
              "C-o" (lambda ()
                      (interactive)
                      (push ?\C-o unread-command-events)
                      (exit-minibuffer)))
            (current-local-map))))
      (isearch-edit-string))))
(advice-add 'isearch-mode :around #'qp--isearch-region-then-edit)


;=======================================
;  Highlighting Functions
;=======================================

;; hi-lock rotates between 11 faces natively
(require 'hi-lock)
(setq hi-lock-face-defaults '("hi-pink" "hi-yellow" "hi-salmon" "hi-green" "hi-blue" "hi-aquamarine"))

(defun qp-highlight()
  "(Un)toggles hi-lock highlights for a symbol at cursor."
  (interactive)
  (let* ((case-fold-search nil)
         (sym (thing-at-point 'symbol t)))
    (unless sym
      (user-error "No symbol at point"))
    (let ((regexp (concat "\\_<" (regexp-quote sym) "\\_>"))
          (before (length hi-lock-interactive-patterns)))
      (ignore-errors (hi-lock-unface-buffer regexp))
      (when (= before (length hi-lock-interactive-patterns))
        ;; nothing was removed, so it wasn't highlighted: highlight it
        (hi-lock-face-buffer
         regexp
         (intern (nth (mod before (length hi-lock-face-defaults))
                      hi-lock-face-defaults)))))))
 
(defun qp-highlight-clear()
  "Removes all hi-lock highlights present in buffer."
  (interactive)
  (require 'hi-lock)
  (hi-lock-unface-buffer t))


;=======================================
;  Misc
;=======================================

(defun qp-todo()
  "Create notes.org in `user-emacs-directory' if missing, then open it."
  (interactive)
  (let ((file (expand-file-name "notes.org" user-emacs-directory)))
    (unless (file-exists-p file)
      (make-empty-file file))
    (find-file file)))
(defalias 'qp-notes 'qp-todo)


(defun qp-timestamp()
  "Inserts timestamp in D-M-Y | H:M"
  (interactive)
  (let* ((system-time-locale "C")
    (day (string-to-number (format-time-string "%d"))))
    (insert
       (format-time-string (concat
         (qp--timestamp-ordinal day) " %B %Y | %H:%Mh")))))
(defun qp--timestamp-ordinal(n)
    (let
        ((suffix (cond
            ((memq n '(11 12 13)) "th")
            ((= (% n 10) 1) "st")
            ((= (% n 10) 2) "nd")
            ((= (% n 10) 3) "rd")
            (t "th"))))
        (concat (number-to-string n) suffix)))


(defun qp-print()
  "Inserts a print statement, focuses cursor on variable name."
  (interactive)
  (let* ((start (point))
         (snippet
          (cond
           ((derived-mode-p 'rust-mode)
            "println!(\"{}\", VAR);")
           ((derived-mode-p 'python-mode)
            "print(VAR)")
           ((derived-mode-p 'js-mode 'js-ts-mode 'typescript-mode
                            'typescript-ts-mode 'tsx-ts-mode)
            "console.log(VAR);")
           ((derived-mode-p 'zig-mode)
            "std.debug.print(\"{}\", .{VAR});")
           ((derived-mode-p 'go-mode)
            "fmt.Println(VAR)")
           ((derived-mode-p 'c++-mode)
            "std::cout << VAR << std::endl;")
	   ((derived-mode-p 'ruby-mode)
	    "cprint VAR")
           ((derived-mode-p 'java-mode)
            "System.out.println(VAR);")
           ((derived-mode-p 'c3-mode 'c3-ts-mode)
            "io::printn(VAR);")
           (t
            "printf(\"%d\\n\", VAR);"))))
    (insert snippet)
    (goto-char start)
    (search-forward "VAR")))


;; Compilation
;; https://www.reddit.com/r/emacs/comments/1gmjpn1/comment/lw4kgya/
(defun user-native-recompile()
  "Prune eln cache and native recompile everything on `package-user-dir'."
  (interactive)
  (native-compile-prune-cache)
  (native-compile-async package-user-dir 'recursively))


(defun user-how-big-is-a-billion()
  "No politics please."
  (interactive)
  (let ((n 0)
        (start (float-time))
        (numbs '((1000          . "thousand")
                 (1000000       . "million")
                 (10000000      . "ten million")
                 (100000000     . "hundred million")
                 (1000000000    . "billion")
                 (1000000000000 . "trillion"))) 
        (log nil))
    (while (< n 10000000)
      (setq n (1+ n))
      (when (and numbs (= n (caar numbs)))
        (let ((line (format "%s: %.3f s" (cdar numbs) (- (float-time) start))))
          (message "%s" line)
          (push line log))
        (pop numbs)))
    (message "%s" (mapconcat #'identity (nreverse log) "\n"))))
(byte-compile 'qp-how-big-is-a-billion)


;=======================================
;  Compile
;=======================================

(setopt compilation-ask-about-save nil) 
(setq compilation-scroll-output t)
(setq compilation-auto-jump-to-first-error t)
(setq compilation-max-output-line-length nil)

; Auto Complete
(defun qp--compile-guesser()
  (if-let ((name (buffer-file-name)))
      (let* ((file (shell-quote-argument (file-name-nondirectory name)))
             (base (shell-quote-argument
                    (file-name-sans-extension (file-name-nondirectory name)))))
        (pcase (file-name-extension name)
          ("c"    (format "gcc -Wall -o %s %s" base file))
          ("cpp"  (format "clang++ -Wall -o %s %s" base file))
          ("rs"   (format "rustc %s" file))
          ("go"   (format "go build %s" file))
          ("java" (format "javac %s" file))
          (_      "")))
    ""))
(setq-default compile-command '(qp--compile-guesser))


(provide 'workflow)
;;; workflow.el ends here
