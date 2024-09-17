;;; do-this-now.el --- Do This Now  -*- lexical-binding: t -*-
;;
;; Copyright (C) 2024 Taro Sato
;;
;; Author: Taro Sato <okomestudio@gmail.com>
;; URL: https://github.com/okomestudio/
;; Version: 0.1
;; Keywords:
;; Package-Requires: ((emacs "29.1") (alert "1.2"))
;;
;;; License:
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; A notification scheduler for Emacs.
;;
;;; Code:

(require 'alert)

(defgroup do-this-now nil
  "Group for `do-this-now'."
  :prefix "do-this-now-")

(defcustom do-this-now-interval 2400
  "Time in second before alert trigger."
  :group 'do-this-now)

(defcustom do-this-now-message "Hey, do this now!!"
  "Message to show."
  :group 'do-this-now)

(defcustom do-this-now-title "Do This Now!"
  "Message title to show."
  :group 'do-this-now)

(defvar do-this-now--timer nil
  "Timer object for alert. Use `cancel-timer' to cancel a scheduled alert.")

(defun do-this-now-alert ()
  (alert do-this-now-message
         :title do-this-now-title
         :severity 'high)
  (do-this-now-setup-next-alert))

(defun do-this-now-start-timer-for-next-alert ()
  "Schedule the next alert.
If a scheduled alert exists, this function cancels it and
restarts the timer."
  (interactive)
  (when do-this-now--timer
    (cancel-timer do-this-now--timer))
  (setq do-this-now--timer
        (run-with-timer do-this-now-interval nil #'do-this-now-alert)))

(defalias 'do-this-now-restart 'do-this-now-start-timer-for-next-alert)

(defun do-this-now--hook ()
  (do-this-now-start-timer-for-next-alert)
  (remove-hook 'post-command-hook #'do-this-now--hook))

(defun do-this-now-setup-next-alert ()
  (add-hook 'post-command-hook #'do-this-now--hook))

(do-this-now-setup-next-alert)

(provide 'do-this-now)
;;; do-this-now.el ends here
