;; -*- coding: utf-8; lexical-binding: t; -*-

(defvar dressing-dir (expand-file-name "dressing" user-emacs-directory))


; ------------------------------------------- ASCII -------------------------------------------- ;

(defvar ascii-file (expand-file-name "ascii.txt" dressing-dir))
(defvar ascii-separator "%%%")
(defvar ascii-default-message (default-value 'initial-scratch-message))

(unless (file-exists-p dressing-dir)
  (make-directory dressing-dir :parents))

(defun user--ascii-random()
  (when (string= (buffer-name) "*scratch*")
    (if (file-readable-p ascii-file)
        (let ((arts (with-temp-buffer
                      (insert-file-contents ascii-file)
                      (split-string (buffer-string)
                                    (regexp-quote ascii-separator)
                                    t "[ \t\n]+"))))
          (if arts
              (concat (nth (random (length arts)) arts) "\n\n")
            ascii-default-message))
      ascii-default-message)))

(setq initial-scratch-message (user--ascii-random))

(defun user-ascii(n)
  (interactive "nASCII number: ")
  (unless (file-readable-p ascii-file)
    (user-error "No file at %s" ascii-file))
  (let* ((arts (with-temp-buffer
                 (insert-file-contents ascii-file)
                 (split-string (buffer-string)
                               (regexp-quote ascii-separator)
                               t "[ \t\n]+")))
         (count (length arts)))
    (if (or (< n 1) (> n count))
        (user-error "Pick a number between 1 and %d" count)
      (insert (nth (1- n) arts) "\n\n"))))



; -------------------------------------- FRAME ANIMATIONS -------------------------------------- ;

(defvar anim-file (expand-file-name "anims.txt" dressing-dir))
(defvar anim-separator "%%%")
(defvar anims-pause  180)          ; seconds between animations
(defvar anims-length 15)           ; seconds per animation
(defvar anims-tick   0.8)          ; seconds per frame

(defvar anims-list   nil)
(defvar anims-index  0)
(defvar anims-frames nil)
(defvar anims-frame  0)
(defvar anims-buffer nil)
(defvar anims-timer  nil)

(defconst user--anims-emoji-range
  "[\u2190-\u21ff\u2300-\u23ff\u25a0-\u27bf\u2900-\u297f\u2b00-\u2bff\U0001f000-\U0001faff]"
  "Characters that may have a colour emoji presentation, except braille.")

(defconst user--anims-blank ?\u2800
  "Blank space that KDE won't trim.")

(defun user--anims-paddding(lines)
  "Pad LINES with blanks to the width of the widest one."
  (let ((w (apply #'max 0 (mapcar #'string-width lines))))
    (mapcar (lambda (l)
              (concat l (make-string (- w (string-width l)) user--anims-blank)))
            lines)))

(defun user--anims-clean(line)
  "Keep %, keep whitespace, and force monochrome."
  (let* ((s (replace-regexp-in-string "%" "%%" line t t))
         (s (replace-regexp-in-string "[ \t]" (string user--anims-blank) s t t))
         (s (string-replace "\ufe0f" "" s)))
    (replace-regexp-in-string
     (concat "\\(" user--anims-emoji-range "\\)\ufe0e?")
     "\\1\ufe0e" s)))

(defun user--anims-load(file)
  (with-temp-buffer
    (insert-file-contents file)
    (delq nil
          (mapcar (lambda (block)
                    (mapcar #'user--anims-clean
                            (user--anims-paddding
                             (seq-filter (lambda (l) (string-match-p "[^ \t]" l))
                                         (split-string block "\n" t "\r")))))
                  (split-string (buffer-string) anim-separator)))))

(setq frame-title-format
      '(:eval (if anims-frames
                  (nth (mod anims-frame (length anims-frames)) anims-frames)
                "%b")))

(defun user--anims-schedule(delay)
  (force-mode-line-update t)
  (setq anims-timer (run-with-timer delay nil #'user--anims-play)))

(defun user--anims-play()
  (cond
   ;; mid-animation: next frame
   ((and anims-frames (< (* (1+ anims-frame) anims-tick) anims-length))
    (cl-incf anims-frame)
    (user--anims-schedule anims-tick))
   ;; animation over: advance cycle, wait
   (anims-frames
    (setq anims-frames nil
          anims-index (mod (1+ anims-index) (length anims-list)))
    (user--anims-schedule anims-pause))
   ;; buffer changed while waiting: stop without cycling
   ((and anims-buffer (not (equal (buffer-name) anims-buffer)))
    (user-anims-end))
   ;; start the next animation
   (t
    (setq anims-frames (nth anims-index anims-list)
          anims-frame  0
          anims-buffer (buffer-name))
    (user--anims-schedule anims-tick))))

(defun user-anims-end()
  (interactive)
  (when anims-timer (cancel-timer anims-timer))
  (setq anims-timer nil
        anims-frames nil
        anims-buffer nil)
  (force-mode-line-update t))

(defun user-anims-start()
  (interactive)
  (user-anims-end)
  (setq anims-list (or (user--anims-load anim-file)
                       (user-error "No animations found in %s" anim-file)))
  (user--anims-schedule 0))



; ----------------------------------------- FOOTNOTES ----------------------------------------- ;

(defvar messages-file (expand-file-name "footnotes.txt" dressing-dir))
(defvar messages-separator "%%%")
(defvar messages-interval     10)   ; seconds per line
(defvar messages-pause       200)   ; extra seconds on blank (buffer-name) entries
(defvar footnotes-titles     nil)
(defvar footnotes-index        0)
(defvar footnotes-timer      nil)

(defun user--footnotes-load(file)
  (when (file-readable-p file)
    (with-temp-buffer
      (insert-file-contents file)
      (append (mapcan (lambda (block)
                        (cons "" (split-string block "\n" t "[ \t\r]+")))
                      (split-string (buffer-string)
                                    (regexp-quote messages-separator)
                                    t "[ \t\n\r]+"))
              (list "")))))

(defun user--footnotes-title()
  (let ((s (nth footnotes-index footnotes-titles)))
    (if (or (null s) (string-empty-p s))
        (buffer-name)
      s)))

(defun user--footnotes-cycle()
  (if (null footnotes-titles)
      (user-footnotes-end)
    (setq footnotes-index (mod (1+ footnotes-index) (length footnotes-titles)))
    (force-mode-line-update t)
    (setq footnotes-timer
          (run-with-timer
           (if (string-empty-p (nth footnotes-index footnotes-titles))
               (+ messages-interval messages-pause)
             messages-interval)
           nil #'user--footnotes-cycle))))

(defun user-footnotes-end()
  (interactive)
  (when footnotes-timer (cancel-timer footnotes-timer))
  (setq footnotes-timer nil
        frame-title-format "%b")
  (force-mode-line-update t))

(defun user-footnotes-start()
  (interactive)
  (user-footnotes-end)
  (unless (file-readable-p messages-file)
    (user-error "No file at %s" messages-file))
  (setq footnotes-titles (user--footnotes-load messages-file))
  (if (null footnotes-titles)
      (user-error "No footnotes found in %s" messages-file)
    (setq footnotes-index 0
          frame-title-format '(:eval (user--footnotes-title)))
    (user--footnotes-cycle)))


;; dressing.el ends here
