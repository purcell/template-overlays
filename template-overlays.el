(require 'cl)
(require 'ov)

(defun ov-regexp-replace (regexp replace &optional beg end)
  "Make overlays spanning the regions that match REGEXP.
REPLACE should be a function that is called to replace the matched REGEXP.
If BEG and END are numbers, they specify the bounds of the search."
  (save-excursion
    (goto-char (or beg (point-min)))
    (let (ov-or-ovs finish)
      (ov-recenter (point-max))
      (while (and (not finish) (re-search-forward regexp end t))
        ;; Apply only when there are not overlays already
        (when (not (overlays-at (match-beginning 0)))
          (let ((ov (ov-make (match-beginning 0)
                             (match-end 0)
                             nil (not ov-sticky-front) ov-sticky-rear)))
            (let ((replacement (funcall replace
                                        (buffer-substring-no-properties
                                         (match-beginning 0)
                                         (match-end 0)))))
              (overlay-put ov 'display replacement))
            (setq ov-or-ovs (cons ov ov-or-ovs))))
        (when (= (match-beginning 0) (match-end 0))
          (if (eobp)
              (setq finish t)
            (forward-char 1))))
      ov-or-ovs)))

(defvar tov-default-delimiters
  '(("{%" "%}" face (:weight bold))
    ("{{" "}}" face (:box t))))

(defvar tov-delimiters tov-default-delimiters
  "Template overlays delimiters. A list of (delim-from delim-to &rest options)")

(defun tov-set-overlays (&optional force)
  "Sets overlays in the current buffer"

  (dolist (delim tov-delimiters)
    (destructuring-bind (from-delim to-delim &rest options)
        delim
      (apply #'ov-set
             (ov-regexp-replace
              (concat from-delim "\s*\\(.*?\\)\s*" to-delim)
              (lambda (match)
                (let ((content (buffer-substring-no-properties
                                (match-beginning 1)
                                (match-end 1))))
                  content)))
              options)))
  t)

(defun overlays-at-point ()
  (overlays-at (point)))

(defun delete-overlays-at-point ()
  (mapcar 'delete-overlay (overlays-at (point))))

(defun tov-update-overlays ()
  (unless (equal (point) last-post-command-position)
    (let ((my-current-word (thing-at-point 'word)))
      (tov-set-overlays)
      (delete-overlays-at-point))
    (setq last-post-command-position (point))))

(define-minor-mode template-overlays-mode
  "Template overlays minor mode"
  :lighter " TOv"

  (require 'ov)
  
  (message "Template overlays is %s" (if template-overlays-mode "on" "off"))

  (make-variable-buffer-local 'last-post-command-position)
  (make-variable-buffer-local 'last-current-word)
  
  (add-to-list 'post-command-hook #'tov-update-overlays))

(provide 'template-overlays)
