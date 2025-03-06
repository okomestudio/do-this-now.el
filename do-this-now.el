;;; do-this-now.el --- Do This Now  -*- lexical-binding: t -*-
;;
;; Copyright (C) 2024-2025 Taro Sato
;;
;; Author: Taro Sato <okomestudio@gmail.com>
;; URL: https://github.com/okomestudio/do-this-now.el
;; Version: 2.1
;; Keywords: convenience notification message
;; Package-Requires: ((emacs "29.1") (alert "1.2") (log4e "0.4.1"))
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
;; A very minimal notification scheduler for Emacs.
;;
;; To enable logging, call `do-this-now--log-enable-logging'. If
;; anything has logged, they can be viewed by
;; `do-this-now--log-open-log'.
;;
;;; Code:

(require 'alert)
(require 'log4e)

(log4e:deflogger "do-this-now" "%t [%l] %m" "%H:%M:%S")

(defgroup do-this-now nil
  "Group for `do-this-now'."
  :group 'emacs
  :prefix "do-this-now-")

(defcustom do-this-now-active-status-hook 'post-command-hook
  "Hook to use for user activity.
An alert should be scheduled on the first user activity after an
extended idle period. The default, `post-command-hook', is chosen as a
command invocation should detect user activity."
  :group 'do-this-now)

(defcustom do-this-now-idle-interval 600
  "If idle for this many seconds, cancel and reschedule alert."
  :group 'do-this-now)

(defcustom do-this-now-interval 2400
  "Time in second before alert trigger."
  :group 'do-this-now)

(defcustom do-this-now-message "Hey, do this now!!"
  "Message to show."
  :group 'do-this-now)

(defcustom do-this-now-title "Do This Now!"
  "Message title to show."
  :group 'do-this-now)

(defvar do-this-now--last-user-activity nil
  "Float timestamp of last user activity.")

(defvar do-this-now--timer nil
  "Timer object for alert.")

(defvar do-this-now--timer-idle-handler nil
  "Timer object for idle handler.")

(defvar do-this-now--idle-handler-check-interval 60
  "Idle handler check interval.")

;; (defun do-this-now--message (format-string &rest args)
;;   "Display a debug message.
;; The verbosity is set by `do-this-now-debug'. See the documentation for
;; `message' about what FORMAT-STRING and ARGS mean."
;;   (when do-this-now-debug
;;     (apply #'message `(,(concat "do-this-now: " format-string) ,@args))))

(defun do-this-now--cancel-idle-handler ()
  "Cancel the currently active idle handler."
  (when do-this-now--timer-idle-handler
    (setq do-this-now--timer-idle-handler
          (cancel-timer do-this-now--timer-idle-handler))))

(defun do-this-now--cancel-scheduled-alert ()
  "Cancel the currently active scheduled alert."
  (when do-this-now--timer
    (setq do-this-now--timer
          (cancel-timer do-this-now--timer))))

(defun do-this-now--cancel-scheduled-alert-if-idle ()
  "Cancel the scheduled alert if the user is idle for an extended time."
  (do-this-now--cancel-idle-handler)
  (let* ((now (float-time))
         (dt (- now (or do-this-now--last-user-activity now))))
    (do-this-now--log-debug "Idle for %f sec" dt)
    (if (< dt do-this-now-idle-interval)
        (setq do-this-now--timer-idle-handler
              (run-with-timer do-this-now--idle-handler-check-interval nil
                              #'do-this-now--cancel-scheduled-alert-if-idle))
      (do-this-now--log-info "Cancel scheduled alert due to idleness")
      (do-this-now--cancel-scheduled-alert)
      (do-this-now--start-timer-on-next-activity))))

(defun do-this-now--schedule-next-alert ()
  "Schedule the next alert.
If a scheduled alert exists, this function cancels it and restarts the
timer."
  (do-this-now--cancel-scheduled-alert)

  (defun do-this-now--trigger-scheduled-alert ()
    (do-this-now-alert)
    (do-this-now--start-timer-on-next-activity))

  (do-this-now--log-info "Schedule alert to trigger in %f sec"
                         do-this-now-interval)
  (setq do-this-now--timer
        (run-with-timer do-this-now-interval nil
                        #'do-this-now--trigger-scheduled-alert))

  (do-this-now--cancel-scheduled-alert-if-idle))

(defun do-this-now--hook ()
  "Hook to run a scheduler."
  (remove-hook do-this-now-active-status-hook #'do-this-now--hook)
  (do-this-now--schedule-next-alert))

(defun do-this-now--start-timer-on-next-activity ()
  "Set up hook to start timer on the next activity."
  (do-this-now--log-info "Schedule alert on next user activity")
  (add-hook do-this-now-active-status-hook #'do-this-now--hook))

(defun do-this-now--last-user-activity-set ()
  "Set the last user activity timestamp."
  (setq do-this-now--last-user-activity (float-time)))

;;; Public functions

(defun do-this-now-alert ()
  "Trigger an alert right now and set up the next one."
  (interactive)
  (do-this-now--log-info "Make an alert titled %s" do-this-now-title)
  (alert do-this-now-message :title do-this-now-title :severity 'high))

(defalias 'do-this-now-reschedule #'do-this-now--schedule-next-alert)

;;; Minor mode

(defun do-this-now--activate ()
  "Activate `do-this-now-mode'."
  (add-hook do-this-now-active-status-hook
            #'do-this-now--last-user-activity-set)
  (do-this-now--start-timer-on-next-activity))

(defun do-this-now--deactivate ()
  "Deactivate `do-this-now-mode'."
  (do-this-now--cancel-idle-handler)
  (do-this-now--cancel-scheduled-alert)
  (remove-hook do-this-now-active-status-hook
               #'do-this-now--last-user-activity-set))

;;;###autoload
(define-minor-mode do-this-now-mode
  "A very minimal notification scheduler for Emacs."
  :group 'do-this-now
  :lighter "do-this-now-mode"
  :keymap nil
  (if do-this-now-mode (do-this-now--activate) (do-this-now--deactivate)))

(provide 'do-this-now)
;;; do-this-now.el ends here
