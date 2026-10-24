;;; workflow-modes.el  -*- lexical-binding: t; -*-

(define-minor-mode qp-mode
  "Enables `qp-keywords-mode', `qp-dired-mode' , `qp-electric-mode'"
  :lighter " qp"
  (let ((arg (if qp-mode 1 -1)))
    (qp-keywords-mode arg)
    (qp-electric-mode arg)
    (qp-dired-mode    arg)
))
(global-set-key (kbd "C-c qp")  'qp-mode)

;=======================================
;  Dired
;=======================================

(define-minor-mode qp-dired-mode
  "Establishes a tidy version of dired."
  :init-value nil
  (if qp-dired-mode
      (if (not (derived-mode-p 'dired-mode))
          (progn
            (setq qp-dired-mode nil)
            (when (called-interactively-p 'any)
              (user-error "qp-dired-mode only works in Dired buffers")))
        (setq-local dired-kill-when-opening-new-dired-buffer t)
        (setq-local delete-by-moving-to-trash t)
        (setq-local dired-isearch-filenames 'dwim)
        (dired-hide-details-mode 1))
    ;; Disable when off
    (kill-local-variable 'dired-kill-when-opening-new-dired-buffer)
    (kill-local-variable 'delete-by-moving-to-trash)
    (kill-local-variable 'dired-isearch-filenames)
    (dired-hide-details-mode -1)))
(add-hook 'dired-mode-hook #'qp-dired-mode)

;==================================================
;  Highlighting
;==================================================

(defgroup qp-keywords nil
  "Group for 'qp-keywords-mode'"
  :group 'faces)

(defcustom qp--word-list
  '(("FIXME"          . warning)
    ("FIX ME"         . warning)
    ("BUG"            . warning)
    ("BUGS"           . warning)
    ("PROBLEM"        . warning)
    ("MEMORY"         . warning)
    ("MEMORY LEAK"    . warning)
    ("SLOW"           . warning)
    ("OPTIMIZE"       . warning)
    ("RACE"           . warning)
    ("RACE CONDITION" . warning)
    ("PERFORMANCE"    . warning)
    ("WARNING"        . warning)
    ("NEEDS TESTING"  . warning)
    ("UNTESTED"       . warning)
    ("UNSAFE"         . warning)
    ("FAIL"           . error)
    ("FAILS"          . error)
    ("CRASH"          . error)
    ("CRASHING"       . error)
    ("SEGFAULT"       . error)
    ("BROKEN"         . error)
    ("BORKED"         . error)
    ("NOT WORKING"    . error)
    ("DOES NOT WORK"  . error)
    ("ERROR"          . error)
    ("CAUTION"        . error)
    ("DANGER"         . error)
    ("DO NOT COMMIT"  . error)
    ("DONT COMMIT"    . error)
    ("DON'T COMMIT"   . error)
    ("WORKING"        . success)
    ("FIXED"          . success)
    ("BUG FIXED"      . success)
    ("DONE"           . success)
    ("VERIFIED"       . success)
    ("OK"             . success)
    ("TODO"           . font-lock-constant-face)
    ("TO DO"          . font-lock-constant-face)
    ("IDEA"           . font-lock-constant-face)
    ("REFACTOR"       . font-lock-constant-face)
    ("SEE"            . font-lock-constant-face)
    ("REF"            . font-lock-constant-face)
    ("CLEANUP"        . font-lock-constant-face)
    ("NOTE"           . font-lock-constant-face)
    ("NOTES"          . font-lock-constant-face))
  "Words to highlight, and by what face."
  :type '(alist :key-type string :value-type face)
  :group 'qp-keywords)


(defun qp--face-for(text)
  "Returs the desired face for keyword."
  (cdr (assoc-string text qp--word-list t)))


(defun qp--font-lock-rules()
  "Grabs rules to apply."
  (let* ((words (sort (mapcar #'car qp--word-list)
                      (lambda (a b) (> (length a) (length b)))))
         (regexp (concat "\\<" (regexp-opt words) "\\>")))
    `((,regexp 0 (qp--face-for (match-string 0)) prepend))))


(define-minor-mode qp-keywords-mode
  "Highlights keywords stored in 'qp--word-list'"
  :group 'qp-keywords
  (if qp-keywords-mode
      (font-lock-add-keywords nil (qp--font-lock-rules) 'append)
    (font-lock-remove-keywords nil (qp--font-lock-rules)))
  (font-lock-flush))


;==================================================
;  Electric Mode
;==================================================
; Copies behaviour of electric-pair and electric-quote
; On region highlight, delete matching braces when closed brace is typed
;     delete-pair is useful, but slow for small tasks
; On region highlight, wrap it with paired braces when open brace is typed
;     copies native M-( behaviour with support for other brace types
; On empty space, auto inserts and deletes brace or quote pairs

(defvar qp-electric-mode)
(defgroup qp-electric nil
  "Customization group for `qp-electric-mode'"
  :group 'editing)

(defcustom qp--electric-pairs
  '((?\( . ?\)) (?\{ . ?\}) (?\[ . ?\])
    (?\" . ?\") (?\' . ?\') (?\` . ?\`))
  "Pairs handled by `qp-electric-mode'"
  :group 'qp-electric
  :type '(alist :key-type character :value-type character))

(defcustom qp--electric-region-only '(?\' ?\`)
  "These are inserted in pairs on a region highlight, but not in blank space."
  :group 'qp-electric
  :type '(repeat character))

;--------------------------------------------------
; Helpers

(defun qp--electric-remark(begin end forward)
  "Helper for (un)wrap behaviour."
  (set-mark (if forward begin end))
  (goto-char (if forward end begin))
  (setq deactivate-mark nil))


(defun qp--electric-insert(open close)
  "Uses native emacs M-( command to insert pairs."
  (let ((parens-require-spaces nil))
    (insert-pair nil open close)))


(defun qp--electric-get-wrappers(open close begin end)
  "Finds the pair to delete within a region."
  (if (eq open close)
      (and (> end (1+ begin))
           (eq (char-after begin) open)
           (eq (char-before end) close)
           (cons begin (1- end)))
    (save-excursion
      (save-restriction
        (narrow-to-region begin end)
        (goto-char (point-min))
        (when (search-forward (string open) nil t)
          (let* ((o (1- (point)))
                 (c (ignore-errors (scan-sexps o 1))))
            (and c (cons o (1- c)))))))))

;--------------------------------------------------
; Core Behaviour

(defun qp--electric-unwrap (open close beg end)
  "Unwraps a region directly surrounded by pair elements in `qp--electric-pairs'"
  (let ((pos (cond
              ((qp--electric-get-wrappers open close beg end))
              ((and (eq (char-before beg) open)
                    (eq (char-after end) close)
                    (cons (1- beg) end))))))
    (when pos
      (combine-change-calls (car pos) (1+ (cdr pos))
        (delete-region (cdr pos) (1+ (cdr pos)))
        (delete-region (car pos) (1+ (car pos))))
      (if (= (car pos) (1- beg))
          (cons (1- beg) (1- end))
        (cons beg (- end 2))))))


(defun qp--electric-handler ()
  "Handler for typed pair characters."
  (interactive)
  (let* ((ch last-command-event)
         (pair (or (assq ch qp--electric-pairs) (rassq ch qp--electric-pairs)))
         (open (car pair))
         (close (cdr pair)))
    (cond
     ((not pair) (self-insert-command 1))
     ((use-region-p)
      (let* ((beg (region-beginning))
             (end (region-end))
             (forward (= (point) end))
             (new (and (eq ch close) (qp--electric-unwrap open close beg end))))
        (cond
         ;; closer
         (new (qp--electric-remark (car new) (cdr new) forward))
         ;; opener
         ((eq ch open)
          (qp--electric-insert open close)
          (qp--electric-remark (1+ beg) (1+ end) forward))
         (t (message "No matching %c%c pair found" open close)))))
     ((memq ch qp--electric-region-only) (self-insert-command 1))
     ((and (eq ch close) (eq (char-after) close)) (forward-char 1))
     ((eq ch open) (qp--electric-insert open close))
     (t (self-insert-command 1)))))

;--------------------------------------------------
; Deletion Behaviour

(defvar qp--electric-delete-override(kbd "DEL")
  "Key for `qp--electric-backspace'
   DELETE key functions normally, allowing erasure of a single paired element.")

(defun qp--electric-emacs-del()
  "Releases native delete event from `qp-electric-mode'"
  (let ((qp-electric-mode nil))
    (call-interactively (key-binding qp--electric-delete-override))))

(defun qp--electric-backspace()
  "Pair deletion assistance."
  (interactive)
  (let ((prev (char-before))
        (next (char-after))
        (p (point)))
    (cond
     ;; C-u 1 allows for normal deletion event
     ((or (use-region-p) current-prefix-arg (not prev))
      (qp--electric-emacs-del))
     ;; (█)  ->   deleting the opener also deletes its closer
     ((and next (eq (cdr (assq prev qp--electric-pairs)) next))
      (delete-region (1- p) (1+ p)))
     ;; ()█  ->   deleting the closer deletes the pair
     ((eq (cdr (assq (char-before (1- p)) qp--electric-pairs)) prev)
      (delete-region (- p 2) p))
     (t (qp--electric-emacs-del)))))

;--------------------------------------------------

(defvar qp--electric-pairs-map
  (let ((map (make-sparse-keymap)))
    (dolist (p qp--electric-pairs)
      (dolist (c (list (car p) (cdr p)))
        (define-key map (char-to-string c) #'qp--electric-handler)))
    (define-key map qp--electric-delete-override #'qp--electric-backspace)
    map)
  "Keymap for `qp-electric-mode'.")


(define-minor-mode qp-electric-mode
  "Electric pairing support for paired characters.'
  
  1) Auto inserts or deletes braces and quotes in empty spaces. 
  2) With selected region, wraps or unwraps if a open or closed brace was typed.
  3) With selected region, wraps or unwraps double quotes, single quotes, and backquotes."
  :keymap qp--electric-pairs-map)


;--------------------------------------------------

(qp-mode 1)

;;; workflow-modes.el ends here
