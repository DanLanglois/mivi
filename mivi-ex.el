;;; mivi-ex.el --- MiVi ex commands -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'mivi-common)

(defvar mivi-ex--history nil)

;; ex commands
(defun mivi-ex ()
  "Read ex command from user input and dispatch it to other ex functions."
  (interactive)
  (let* ((default (car mivi-ex--history))
         (str (read-string (if default (format ":(default %s) " default) ":")
                           nil 'mivi-ex--history default))
         (cmdspec (mivi-ex--parse-command str)))
    (pcase (plist-get cmdspec :command)
      ("d" (mivi-ex--delete (plist-get cmdspec :range))))))

(defun mivi-ex--delete (range)
  "Delete lines within RANGE."
  (let ((beg (save-excursion
               (mivi-ex--goto-line (car range))
               (point)))
        (end (save-excursion
               (mivi-ex--goto-line (1+ (cdr range)))
               (point))))
    (kill-region beg end)))

;; Internal functions
(defun mivi-ex--goto-line (num)
  "Go to line NUM."
  (goto-char (point-min))
  (forward-line (1- num)))

(defun mivi-ex--parse-command (str)
  "Parse ex command line provided as STR.
It returns plist of :command, :arg and :range."
  (let (beg end)
    (pcase (mivi-ex--parse-linespec str)
      (`(,num . ,rest)
       (setq beg num)
       (setq str rest)))
    (when (string-match-p "^," str)
      (pcase (mivi-ex--parse-linespec (substring str 1))
        (`(,num . ,rest)
         (setq end num)
         (setq str rest))))
    (if (string-match "\\([a-z]+\\)\\(.*\\)" str)
        (list :command (match-string 1 str)
              :arg (match-string 2 str)
              :range (cons beg (or end beg))))))

(defun mivi-ex--parse-linespec (str)
  "Parse ex line number spec provided as STR.
It returns cons of line number and rest of string."
  (let (num)
    (cond
     ((string-match "^[0-9]+" str)
      (setq num (string-to-number (match-string 0 str)))
      (setq str (substring str (match-end 0))))
     ((string-match-p "^\\." str)
      (setq num (line-number-at-pos))
      (setq str (substring str 1)))
     ((string-match "^'\\(.\\)" str)
      (let* ((c (string-to-char (match-string 1 str)))
             (p (gethash c mivi--mark-slots)))
        (setq str (substring str 2))
        (if p
            (setq num (save-excursion
                        (goto-char p)
                        (line-number-at-pos)))
          (user-error "`%s': Marker is not set." c))))
     ((string-match-p "^\\$" str)
      (setq num (save-excursion
                  (goto-char (point-max))
                  (line-number-at-pos)))
      (setq str (substring str 1)))
     (t (setq num (line-number-at-pos))))

    (when (string-match "^\\([-+]\\)\\([0-9]+\\)?" str)
      (setq num (funcall
                 (if (equal (match-string 1 str) "-") #'- #'+)
                 num
                 (if (match-string 2 str)
                     (string-to-number (match-string 2 str))
                   1)))
      (setq str (substring str (match-end 0))))
    (cons num str)))

(provide 'mivi-ex)
;;; mivi-ex.el ends here
