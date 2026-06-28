;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/main.lisp

(defpackage #:dps.meta
  (:use #:cl)
  (:import-from #:dps.meta.ci.generate    #:generate-ci-workflow)
  (:import-from #:dps.meta.properties.c99-binary    #:c99-binary-scaffold)
  (:import-from #:dps.meta.properties.c99-header    #:c99-header-scaffold)
  (:import-from #:dps.meta.properties.lisp-actor    #:lisp-actor-scaffold)
  (:import-from #:dps.meta.properties.shell-bats    #:shell-bats-scaffold)
  (:import-from #:dps.meta.properties.quadlet-stack #:quadlet-stack-scaffold)
  (:export #:main))

(in-package #:dps.meta)

(defun read-git-config ()
  "Parse .git/config via cl-inix — no fork, no subprocess."
  (let* ((config-path (merge-pathnames #P".git/config" (uiop:getcwd)))
         (config      (cl-inix:read config-path))
         (meta        (cdr (assoc "meta" config :test #'string=))))
    (unless meta
      (error "No [meta] section in .git/config — set meta.type, meta.application, ~
              meta.role, meta.version, meta.branch"))
    (flet ((req (key)
             (or (cdr (assoc key meta :test #'string=))
                 (error "meta.~A not set in .git/config" key))))
      (list :type        (req "type")
            :application (req "application")
            :role        (req "role")
            :version     (req "version")
            :branch      (req "branch")
            :licence     (or (cdr (assoc "licence" meta :test #'string=))
                             "bsd-2-clause")))))

(defparameter *dispatch*
  '(("c99-binary"    . c99-binary-scaffold)
    ("c99-header"    . c99-header-scaffold)
    ("lisp-actor"    . lisp-actor-scaffold)
    ("shell-bats"    . shell-bats-scaffold)
    ("quadlet-stack" . quadlet-stack-scaffold)))

(defun main ()
  (handler-case
      (let* ((config (read-git-config))
             (type   (getf config :type))
             (entry  (assoc type *dispatch* :test #'string=)))
        (unless entry
          (error "Unknown meta.type: ~S. Valid: ~{~A~^, ~}"
                 type (mapcar #'car *dispatch*)))
        (format t "~&[dps-meta] ~A ~A (~A)~%"
                (getf config :application) (getf config :version) type)
        ;; 1. Governance + identity files
        (funcall (symbol-function (cdr entry)) config)
        ;; 2. .github/workflows/ci.yml via 40ants/CI
        (generate-ci-workflow config)
        (format t "~&[dps-meta] Done.~%")
        (uiop:quit 0))
    (error (e)
      (format *error-output* "~&[dps-meta] ERROR: ~A~%" e)
      (uiop:quit 1))))
