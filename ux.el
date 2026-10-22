;; -*- coding: utf-8; lexical-binding: t; -*-

;=============================================
;  Modes
;=============================================

(setq-default
    tab-width                             4
    indent-tabs-mode                    nil
    compilation-scroll-output             t
    visible-bell                          t
    show-paren-mode                       t
    electric-pair-mode                  nil   ; qp-electric-mode
    electric-quote-mode                 nil   ;                 
    display-line-numbers-widen            t
    display-line-numbers-type     'relative
    )

(add-hook 'after-init-hook
    (lambda ()
        (which-key-mode                   t)
        ;(menu-bar-mode          early_init)
        ;(tool-bar-mode          early_init)
        (blink-cursor-mode               -1)
        (global-display-line-numbers-mode t)
        (electric-indent-mode            -1)   ; Auto indent on Enter
    ))


;=======================================
;  Tabs
;=======================================
; Stops tabs from shrinking: Emacs v30

(customize-set-variable 'tab-bar-show 1) ; hides tabs when there only one
(setq tab-bar-new-button-show nil)
(push 'tab-bar-tab-name-format-truncated tab-bar-tab-name-format-functions)

(defun qp--limit-tab-width(&optional frame)
  (let* ((frame (or frame (selected-frame)))
         (px (/ (frame-pixel-width frame) 5))
         (ch (/ (frame-width frame) 5)))
    (unless (equal tab-bar-auto-width-min (list px ch))
      (setq tab-bar-auto-width-min (list px ch)
            tab-bar-auto-width-max (list px ch))
      (run-with-idle-timer 0 nil #'force-mode-line-update t))))

(setq tab-bar-auto-width t)
(qp--limit-tab-width)
(add-hook 'window-size-change-functions #'qp--limit-tab-width)


;=============================================
;  Window
;=============================================

;; Auto resize at launch
(defun qp--set-frame-text-width(cols)
  (let ((diff (- cols (window-max-chars-per-line))))
    (set-frame-width nil (+ (frame-width) diff))))
(add-hook 'window-setup-hook (lambda () (qp--set-frame-text-width 100)))

;---------------------------------------------
; Changing the flashing on command fail

;; EMACS 31 VERSION
;; (require 'ring-bell-fns)
;; (setq visible-bell nil
;;       ring-bell-function #'flash-echo-area-bell-function)
;; (setq flash-face-attributes
;;       `(:background ,(face-attribute 'warning :background nil t)
;;         :foreground ,(face-attribute 'warning :foreground nil t)))

;; EMACS 30 VERSION
(setq visible-bell nil)
(defface my-bell-flash
  '((t :inherit warning))
  "What to flash when bell rings.")
(setq ring-bell-function
      (lambda ()
        (let ((bufs (delq nil
                          (list (get-buffer " *Echo Area 0*")
                                (get-buffer " *Echo Area 1*")
                                (window-buffer (minibuffer-window)))))
              (cookies nil))
          (dolist (b (delete-dups bufs))
            (with-current-buffer b
              (push (cons b (face-remap-add-relative 'default 'my-bell-flash))
                    cookies)))
          (force-window-update (minibuffer-window))
          (redisplay t)
          (run-with-timer
           0.1 nil
           (lambda ()
             (dolist (c cookies)
               (when (buffer-live-p (car c))
                 (with-current-buffer (car c)
                   (face-remap-remove-relative (cdr c))))
             (force-window-update (minibuffer-window))))))))

;---------------------------------------------

;; Stops emacs from dividing long lines
(setq-default truncate-lines t)
(add-hook 'after-change-major-mode-hook
          (lambda () (setq truncate-lines t)))

;; Auto Fill width (moves to new line when width is met)
(setq-default fill-column 100)

;; Mouse Scrolling Horizontally
(setq mouse-wheel-scroll-amount '(1 ((shift) . hscroll)))
(setq mouse-wheel-tilt-scroll t)

;; Capping horizontal scrolling so it doesn't keep going and going and going and going and going and going and going and going and going and going and going you get it
(defvar qp--scroll-padding 5 "How many columns of padding after line end.")
(defvar-local qp--longest-cache nil "Stores the longest line width")

(defun qp--longest-line()
  "Width in columns of the longest line in the buffer, cached until the text changes."
  (let ((tick (buffer-chars-modified-tick)))
    (unless (and qp--longest-cache (eq (car qp--longest-cache) tick))
      (setq qp--longest-cache
            (cons tick
                  (save-excursion
                    (save-restriction
                      (widen)
                      (goto-char (point-min))
                      (let ((max 0))
                        (while (progn (end-of-line)
                                      (setq max (max max (current-column)))
                                      (zerop (forward-line 1))))
                        max))))))
    (cdr qp--longest-cache)))

(defun qp--clamp-hscroll(window)
  "Keep WINDOW's horizontal scroll from passing the longest line in the page."
  (when (and (window-live-p window)
             (> (window-hscroll window) 0))
    (with-selected-window window
      (when truncate-lines
        (let* ((avail (- (window-body-width) (line-number-display-width)))
               (limit (max 0 (- (+ (qp--longest-line) qp--scroll-padding) avail))))
          (when (> (window-hscroll) limit)
            (set-window-hscroll window limit)))))))
(add-hook 'pre-redisplay-functions #'qp--clamp-hscroll)



(provide 'ux)
;;; ux.el ends here
