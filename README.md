# do-this-now.el

A notification scheduler for Emacs.

It is very easy to spend too much time in front of Emacs. A regular reminder for doing
something other than sitting in front of a computer would be nice. Maybe you should stand
upand do some stretch every hour or so. Or may be make a cup of coffee.

This tool sets up such a reminder.

The `do-this-now.el` uses [alert.el](https://github.com/jwiegley/alert) as an interface to
access the OS's notification facility.

## Usage

With `use-package`, have the following in the `init-el` file:

``` emacs-lisp
(use-package do-this-now
  :straight (do-this-now
             :host github
             :repo "okomestudio/do-this-now.el")
  :custom ((alert-default-style 'notifications)
           (do-this-now-interval 2400)                 ; notify in 40 minutes
           (do-this-now-message "Hey, do this now!!")
           (do-this-now-title "Do This Now!"))
  :demand t)
```

The notification itself is managed entirely by `alert.el`; see its documentation for finer
control over how the message is displayed.

## TODOs

- [ ] Look for a solution to display notification more prominently in GUI
