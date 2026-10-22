;;; -*- lexical-binding: t -*-

;; File intended for code folding support
;; Current version uses: https://github.com/agzam/occult.el

(use-package occult
  :ensure t)

(occult--mode t)
(customize-set-variable 'occult-indicator " ▼ ")

(global-set-key (kbd "C-c f f") 'occult-toggle)
(global-set-key (kbd "C-c f r") 'occult-reveal-all)
(global-set-key (kbd "C-c f a") 'qp-fold-all)

;=============================================
;  Folding Functions
;=============================================

(defun qp-fold-all()
  "Folds every function, class, etc, in the buffer."
  (interactive)
  (let ((regions (qp--collect-defs)))
    (if (null regions)
        (message "No functions found")
      (save-excursion
        (dolist (region regions)
          (qp--toggle-region (car region) (cdr region))))
      (message "Toggled %d regions" (length regions)))))

;--------------------------------------------------
;  Helper Functions

(defun qp--collect-defs()
  "Returns (begin . end) for every function in the buffer."
  (let (regions)
    (save-excursion
      (goto-char (point-max))
      (while (beginning-of-defun)
        (let ((begin (point))
              (end (save-excursion (end-of-defun) (point))))
          (when (> end begin)
            (push (cons begin end) regions)))))
    regions))

(defun qp--toggle-region(begin end)
  "Applies `occult-toggle' on a region."
  (save-excursion
    (goto-char begin)
    (push-mark end nil t)
    (setq deactivate-mark nil)
    (occult-toggle)
    (deactivate-mark)))


;;; folding.el ends here
