;;----------------------------------------------------------------------
;;----------------------------------------------------------------------
;;-- .emacs
;;----------------------------------------------------------------------
;;----------------------------------------------------------------------

(add-to-list 'load-path "~/.emacs.d/lisp/")

;;----------------------------------------------
;;-- Auto-Saves

(setq delete-old-versions t
      kept-new-versions 6
      kept-old-versions 2
      version-control t
      backup-by-copying t
      vc-make-backup-files t
)

;; Default and per-save backups go here:
(setq backup-directory-alist '(("" . "~/.emacs.d/backups/per-save")))

(defun force-backup-of-buffer ()
  ;; Make a special "per session" backup at the first save of each
  ;; emacs session.
  (when (not buffer-backed-up)
    ;; Override the default parameters for per-session backups.
    (let ((backup-directory-alist '(("" . "~/.emacs.d/backups/per-session")))
          (kept-new-versions 3))
      (backup-buffer)))
  ;; Make a "per save" backup on each save.  The first save results in
  ;; both a per-session and a per-save backup, to keep the numbering
  ;; of per-save backups consistent.
  (let ((buffer-backed-up nil))
    (backup-buffer)))

(add-hook 'before-save-hook  'force-backup-of-buffer)


;;----------------------------------------------
;;-- Packages

;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(package-initialize)

(require 'package)
(add-to-list
  'package-archives
  ; '("melpa" . "http://stable.melpa.org/packages/") ; many packages won't show using stable
  '("melpa" . "http://melpa.milkbox.net/packages/")
 t)

(require 're-builder)
(setq reb-re-syntax 'string)


;;----------------------------------------------
;;-- Display

(setq inhibit-startup-screen t)

;; Prevent emacs from splitting windows when loading files
(setq pop-up-windows nil)

;; Turn off the menu bar
(menu-bar-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode -1)

;; Show lines and columns
(line-number-mode 1)
(column-number-mode 1)

;; Show trailing whitespace
(setq-default show-trailing-whitespace t)

;; Delete trailing whitespace before saving
(add-hook 'before-save-hook 'delete-trailing-whitespace)

(when (not (display-graphic-p))
  (progn (setq frame-background-mode 'dark)
         ; (xterm-mouse-mode)
         ))
         ; also available: gpm-mouse-mode

         ; in xterm-mouse-mode you have to Shift+RightClick to paste from the system
         ; clipboard (shift directs the click to the terminal emulator, not emacs)

;(when (and (not window-system)
;           (string-match "^xterm" (getenv "TERM")))
;  (require 'xterm-title)
;  (xterm-title-mode 1)
;  (message "Set xterm-title-mode"))

;;----------------------------------------------
;;-- Keys and Mice

(global-set-key  "\C-v" 'backward-kill-word)

(defun kill-all-buffers()
  "Kill all buffers, excluding emacs' internal buffers (those
   with a leading space in their name)."
  (interactive)
  (mapc
   (lambda (x)
     (let ((name (buffer-name x)))
       (unless (eq ?\s (aref name 0))
         (kill-buffer x))))
   (buffer-list)))

(global-set-key "\C-xK" 'kill-all-buffers)

;; Set up the keyboard so the delete key on both the regular keyboard
;; and the keypad delete the character under the cursor and to the
;; right under X, instead of the default, backspace behavior.
(global-set-key [delete] 'delete-char)
(global-set-key [kp-delete] 'delete-char)

(global-set-key [home] 'beginning-of-buffer)
(global-set-key [end] 'end-of-buffer)

(global-set-key "\C-xg" 'goto-line)

;; These two set Emacs to work with the X11 primary selection rather
;; than the clipboard.  Uncomment these to differentiate X11
;; selections and explicitly placed clipboard content.
(setq x-select-enable-primary t)
(setq x-select-enable-clipboard nil)
(setq mouse-drag-copy-region t)


;;----------------------------------------------
;;-- Modes

(setq-default
  tab-width 2
  standard-indent 2
  indent-tabs-mode nil)

(setq default-major-mode 'text-mode)

;(setq auto-mode-alist (cons '("\\.as$" . java-mode) auto-mode-alist))
;(setq auto-mode-alist (cons '("\\.hx$" . java-mode) auto-mode-alist))
;(setq auto-mode-alist (cons '("\\.scss$" . css-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\\.svg$" . xml-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.ino$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.ts$" . javascript-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.tsx$" . javascript-mode) auto-mode-alist))
(setq js-indent-level 2)

;(load "auctex.el" nil t t)
;(load "preview-latex.el" nil t t)

(autoload 'scad-mode "scad-mode" "A major mode for editing OpenSCAD code." t)
(add-to-list 'auto-mode-alist '("\\.scad$" . scad-mode))


;;----------------------------------------------
;;-- Scripts

;; Stolen from delorie.com
(defun count-words-region (beginning end)
  "Print number of words in the region."
  (interactive "r")
  (message "Counting words in region ... ")

  (save-excursion
    (let ((count 0))
      (goto-char beginning)
      (while (and (< (point) end)
                  (re-search-forward "\\w+\\W*" end t))
        (setq count (1+ count)))
      (cond ((zerop count)
             (message
              "The region does NOT have any words."))
            ((= 1 count)
             (message
              "The region has 1 word."))
            (t
             (message
              "The region has %d words." count))))))

(global-set-key "\C-x-" 'count-words-region)

(defun fix-lines (start end)
  (interactive "*r")
  (save-excursion
    (save-restriction
      (narrow-to-region start end)
      (goto-char (point-min))
      (replace-regexp "\\([^\n]\\)\n\\([^\n]\\)" "\\1 \\2")
      )
  )
)

(global-set-key "\C-xf" 'fix-lines)


;;----------------------------------------------
;;-- Daemonized utilities
(defun client-save-kill-emacs(&optional display)
  "Save buffers and shutdown the emacs daemon. \
   Call using emacsclient -e '(client-save-kill-emacs)'."

  (let (new-frame modified-buffers active-clients-or-frames)

    ; Check if there are modified buffers or active clients or frames.
    (setq modified-buffers (modified-buffers-exist))
    (setq active-clients-or-frames ( or (> (length server-clients) 1)
					(> (length (frame-list)) 1)
				       ))

    ; Create a new frame if prompts are needed.
    (when (or modified-buffers active-clients-or-frames)
      (setq new-frame (make-frame))

    ; When displaying the number of clients and frames:
    ; subtract 1 from the clients for this client.
    ; subtract 2 from the frames for this frame and the default
    (when (or (not active-clients-or-frames)
              (yes-or-no-p (format "There are currently %d clients and %d frames. Exit anyway?" (- (length server-clients) 1) (- (length (frame-list)) 2))))
      (let ((inhibit-quit t))
        (with-local-quit
          (save-some-buffers))

        (if quit-flag
            (setq quit-flag nil)
          (progn
            (dolist (client server-clients)
              (server-delete-client client))
            (kill-emacs)))
        ))

    (when new-frame (delete-frame new-frame))
    )
    )
  )


(defun modified-buffers-exist()
  "Check there are any buffers that have been modified."
  (let (modified-found)
    (dolist (buffer (buffer-list))
      (when (and (buffer-live-p buffer)
                 (buffer-modified-p buffer)
                 (not (buffer-base-buffer buffer))
                 (or
                  (buffer-file-name buffer)
                  (progn
                    (set-buffer buffer)
                    (and buffer-offer-save (> (buffer-size) 0))))
                 )
        (setq modified-found t)
        )
      )
    modified-found
    )
  )

; https://www.emacswiki.org/emacs/EmacsAsDaemon


;;----------------------------------------------
;;-- Known functions

(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)
(put 'narrow-to-region 'disabled nil)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages (quote (go-mode))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
