;;; mivi.el --- Minimal Vi mode -*- lexical-binding: t -*-

;; Copyright (C) 2014-2016 by Iku Iwasa

;; Author:    Iku Iwasa <iku.iwasa@gmail.com>
;; URL:       https://github.com/iquiw/mivi
;; Version:   0.0.0
;; Package-Requires: ((undo-tree "0.6.5") (emacs "25"))

;;; Commentary:
;;; Code:

(require 'undo-tree)

(defvar mivi--state 'command)
(defvar mivi--last-command nil)
(defvar mivi--last-find nil)
(defvar mivi--number 1)
(defvar-local mivi-insert-mode nil)
(defvar-local mivi-command-mode nil)

(defconst mivi-motion-map
  (let ((map (make-sparse-keymap)))
    (suppress-keymap map)
    (define-key map "^" #'beginning-of-line-text)
    (define-key map "0" #'mivi-number-or-bol)
    (define-key map "$" #'end-of-line)
    (define-key map "b" #'backward-word)
    (define-key map "e" #'mivi-end-of-word)
    (define-key map "h" #'backward-char)
    (define-key map "j" #'next-line)
    (define-key map "k" #'previous-line)
    (define-key map "l" #'forward-char)
    (define-key map "w" #'mivi-forward-word)
    (dotimes (v 9)
      (define-key map (number-to-string (1+ v)) #'mivi-number))
    map))

(defconst mivi-command-map
  (let ((map (copy-keymap mivi-motion-map)))
    (define-key map "A" #'mivi-Append)
    (define-key map "F" #'mivi-Find)
    (define-key map "G" #'mivi-goto-line)
    (define-key map "I" #'mivi-Insert)
    (define-key map "O" #'mivi-Open)
    (define-key map "a" #'mivi-append)
    (define-key map "f" #'mivi-find)
    (define-key map "i" #'mivi-insert)
    (define-key map "o" #'mivi-open)
    (define-key map "u" #'mivi-undo)
    (define-key map "," #'mivi-repeat-find-opposite)
    (define-key map "." #'mivi-repeat)
    (define-key map ";" #'mivi-repeat-find)
    (define-key map (kbd "C-e") #'scroll-up-line)
    (define-key map (kbd "C-y") #'scroll-down-line)
    (define-key map (kbd "C-d") #'mivi-scroll-up)
    (define-key map (kbd "C-u") #'mivi-scroll-down)
    (define-key map (kbd "C-f") #'scroll-up)
    (define-key map (kbd "C-b") #'scroll-down)
    map))

(defconst mivi-insert-map
  (let ((map (make-sparse-keymap)))
    (define-key map [escape] #'mivi-command)
    (define-key map (kbd "C-[") #'mivi-command)
    map))

(defun mivi-nil ()
  (interactive))

(defun mivi-Append ()
  (interactive)
  (end-of-line)
  (mivi--insert-mode))

(defun mivi-append ()
  (interactive)
  (unless (eolp)
    (forward-char))
  (mivi--insert-mode))

(defun mivi-goto-line ()
  (interactive)
  (if (> mivi--number 0)
      (forward-line mivi--number)
    (goto-char (point-max))
    (forward-line (- mivi--number))))


(defun mivi-Insert ()
  (interactive)
  (beginning-of-line)
  (mivi--insert-mode))

(defun mivi-insert ()
  (interactive)
  (mivi--insert-mode))

(defun mivi-Open ()
  (interactive)
  (forward-line 0)
  (newline 1 nil)
  (forward-line -1)
  (mivi--insert-mode))

(defun mivi-open ()
  (interactive)
  (end-of-line)
  (newline 1 nil)
  (mivi--insert-mode))

(defun mivi-scroll-up (&optional arg)
  (interactive "P")
  (cond
   ((not arg) (scroll-up (/ (window-height) 2)))
   ((prefix-numeric-value arg)
    (scroll-up (prefix-numeric-value arg)))))

(defun mivi-scroll-down (&optional arg)
  (interactive "P")
  (cond
   ((not arg) (scroll-down (/ (window-height) 2)))
   ((prefix-numeric-value arg)
    (scroll-down (prefix-numeric-value arg)))))

(defun mivi-number (&optional n)
  (interactive)
  (unless n
    (setq n (string-to-number (this-command-keys))))
  (unless (eq last-command #'mivi-number)
    (setq mivi--number 0))
  (setq mivi--number (+ (* mivi--number 10) n))
  (setq prefix-arg mivi--number))

(defun mivi-number-or-bol ()
  (interactive)
  (if (eq last-command #'mivi-number)
      (mivi-number 0)
    (forward-line 0)))

(defun mivi--get-number ()
  (let ((n (or mivi--number 1)))
    (setq mivi--number 1)
    n))

(defun mivi-command ()
  (interactive)
  (unless (bolp)
    (backward-char))
  (set-frame-parameter nil 'cursor-type 'box)
  (setq mivi--last-command nil)
  (setq mivi-insert-mode nil)
  (setq mivi-command-mode t))

(defun mivi--insert-mode ()
  (set-frame-parameter nil 'cursor-type 'bar)
  (setq mivi-insert-mode t)
  (setq mivi-command-mode nil))

(defun mivi-find (&optional arg ch)
  (interactive "p")
  (let ((ch (or ch (read-char "f-")))
        (sign (if (> arg 0) 1 -1))
        (move? (and (> arg 0) (not (eobp)))))
    (when move?
      (forward-char sign))
    (search-forward (char-to-string ch) nil t arg)
    (when move?
      (forward-char (- sign)))
    (setq mivi--last-find (cons sign ch))))

(defun mivi-Find (&optional arg)
  (interactive "p")
  (mivi-find (- arg)))

(defun mivi-repeat-find (&optional arg)
  (interactive "p")
  (pcase mivi--last-find
    (`(,sign . ,ch) (mivi-find (* sign arg) ch))))

(defun mivi-repeat-find-opposite (&optional arg)
  (interactive "p")
  (pcase mivi--last-find
    (`(,sign . ,ch) (mivi-find (* (- sign) arg) ch))))

(defun mivi-end-of-word (&optional arg)
  (interactive "p")
  (forward-word arg)
  (backward-char))

(defun mivi-forward-word (&optional arg)
  (interactive "p")
  (forward-word arg)
  (skip-syntax-forward " "))

(defun mivi--move-syntax (direction)
  (interactive)
  (let ((skip-func (if (>= direction 0)
                       #'skip-syntax-forward
                     #'skip-syntax-backward)))
    (funcall skip-func " ")
    (let* ((c (char-after))
           (syn (and c (char-syntax c))))
      (funcall skip-func (string syn)))))

(defun mivi-undo ()
  (interactive)
  (if (eq mivi--last-command 'mivi-undo)
      (progn
        (undo-tree-redo)
        (setq mivi--last-command 'mivi-redo))
    (undo-tree-undo)
    (setq mivi--last-command 'mivi-undo)))

(defun mivi-repeat ()
  (interactive)
  (cond
   ((null mivi--last-command)
    (call-interactively last-command)
    (setq mivi--last-command last-command))
   ((eq mivi--last-command 'mivi-undo)
    (undo-tree-undo))
   ((eq mivi--last-command 'mivi-redo)
    (undo-tree-redo))
   (t
    (call-interactively mivi--last-command))))

(defun mivi--number-char-p (ch)
  (and (>= ch ?0) (<= ch ?9)))

(defvar mivi-mode-map-alist
  (list
   (cons 'mivi-insert-mode mivi-insert-map)
   (cons 'mivi-command-mode mivi-command-map)))

(define-minor-mode mivi-local-mode "MiVi command"
  :init-value nil
  (if mivi-local-mode
    (progn
      (setq mivi-command-mode t)
      (setq-local emulation-mode-map-alists
                  (cons mivi-mode-map-alist
                        emulation-mode-map-alists)))))

(defun mivi-local-mode-on ()
  (when (or (derived-mode-p 'prog-mode)
            (derived-mode-p 'text-mode))
    (mivi-local-mode 1)))

(define-globalized-minor-mode mivi-mode mivi-local-mode mivi-local-mode-on)

(provide 'mivi)
;;; mivi.el ends here
