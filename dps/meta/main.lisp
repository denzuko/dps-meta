;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/main.lisp

(defpackage #:dps.meta
  (:use #:cl)
  (:import-from #:dps.meta.properties.c99-binary   #:c99-binary-scaffold)
  (:import-from #:dps.meta.properties.c99-header   #:c99-header-scaffold)
  (:import-from #:dps.meta.properties.lisp-actor   #:lisp-actor-scaffold)
  (:import-from #:dps.meta.properties.shell-bats   #:shell-bats-scaffold)
  (:import-from #:dps.meta.properties.quadlet-stack #:quadlet-stack-scaffold)
  (:export #:main))

(in-package #:dps.meta)

(defun git-config (key)
  (handler-case
      (string-trim '(#\Space #\Newline #\Return)
                   (uiop:run-program (list "git" "config" "--local" key)
                                     :output :string :error-output nil))
    (uiop:subprocess-error () nil)))

(defun read-meta-config ()
  (let* ((type    (git-config "meta.type"))
         (app     (git-config "meta.application"))
         (role    (git-config "meta.role"))
         (version (git-config "meta.version"))
         (branch  (git-config "meta.branch"))
         (licence (or (git-config "meta.licence") "bsd-2-clause")))
    (dolist (pair `(("meta.type" . ,type) ("meta.application" . ,app)
                    ("meta.role" . ,role) ("meta.version" . ,version)
                    ("meta.branch" . ,branch)))
      (unless (cdr pair)
        (error "~A not set — run: git config ~A <value>" (car pair) (car pair))))
    (list :type type :application app :role role
          :version version :branch branch :licence licence)))

(defparameter *dispatch*
  '(("c99-binary"    . c99-binary-scaffold)
    ("c99-header"    . c99-header-scaffold)
    ("lisp-actor"    . lisp-actor-scaffold)
    ("shell-bats"    . shell-bats-scaffold)
    ("quadlet-stack" . quadlet-stack-scaffold)))

(defun main ()
  (handler-case
      (let* ((config (read-meta-config))
             (type   (getf config :type))
             (entry  (assoc type *dispatch* :test #'string=)))
        (unless entry
          (error "Unknown meta.type: ~A" type))
        (format t "~&[dps-meta] ~A ~A (~A)~%"
                (getf config :application) (getf config :version) type)
        (funcall (symbol-function (cdr entry)) config)
        (format t "~&[dps-meta] Done.~%")
        (uiop:quit 0))
    (error (e)
      (format *error-output* "~&[dps-meta] ERROR: ~A~%" e)
      (uiop:quit 1))))
