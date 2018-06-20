;;; template-overlays.el --- Emacs overlays for template systems -*- coding: utf-8; lexical-binding: t -*-

;; Copyright © 2018 Mariano Montone
;;
;; Name: tov
;; Author: Mariano Montone <marianomontone@gmail.com>
;; Maintainer: Mariano Montone <marianomontone@gmail.com>
;; URL: http://www.github.com/mmontone/template-overlays
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.4") (ov "1.0.6"))
;; Keywords: faces, convenience, templates, overlays

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Provides text formatting to template files via Emacs overlays

;;; Code:

(require 'cl)
(require 'ov)

(defun tov-regexp-replace (regexp replace &optional beg end)
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
              (overlay-put ov 'display replacement)
              (overlay-put ov 'category 'tov))
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
  "Template overlays delimiters.  A list of (delim-from delim-to &rest options).")

(defun tov-set-overlays ()
  "Set overlays in the current buffer."

  (dolist (delim tov-delimiters)
    (destructuring-bind (from-delim to-delim &rest options)
        delim
      (apply #'ov-set
             (tov-regexp-replace
              (concat from-delim "\s*\\(.*?\\)\s*" to-delim)
              (lambda (match)
                (let ((content (buffer-substring-no-properties
                                (match-beginning 1)
                                (match-end 1))))
                  content)))
              options)))
  t)

(defun tov-delete-all-overlays ()
  "Remove all template overlays from current buffer."
  (remove-overlays nil nil 'category 'tov))

(defun tov-delete-overlays-at-point ()
  "Delete template overlays at point."
  (mapcar (lambda (ov)
            (when (eql (overlay-get ov 'category) 'tov)
              (delete-overlay ov)))
          (overlays-at (point))))

(defun tov-update-overlays ()
  "Update the template overlays in current buffer."
  (unless (equal (point) last-post-command-position)
    (let ((my-current-word (thing-at-point 'word)))
      (tov-set-overlays)
      (tov-delete-overlays-at-point))
    (setq last-post-command-position (point))))

;;;###autoload
(define-minor-mode template-overlays-mode
  "Template overlays minor mode"
  :lighter " TOv"

  (require 'ov)
  
  (message "Template overlays are %s" (if template-overlays-mode "ON" "OFF"))

  (if template-overlays-mode
      (progn
        (make-variable-buffer-local 'last-post-command-position)
        (make-variable-buffer-local 'last-current-word)
        (add-hook 'post-command-hook 'tov-update-overlays nil t)
        (tov-update-overlays))
    (remove-hook 'post-command-hook 'tov-update-overlays t)
    (kill-local-variable 'last-post-command-position)
    (kill-local-variable 'last-current-word)
    (tov-delete-all-overlays)))

(provide 'template-overlays)

;;; template-overlays.el ends here
