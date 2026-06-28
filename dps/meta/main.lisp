;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/main.lisp
;;;;
;;;; Entry point. Reads meta.* from .git/config via cl-inix (no fork),
;;;; applies Consfigurator defproplist for governance files via :local,
;;;; then calls 40ants/CI generate to emit .github/workflows/ci.yml.

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

;;; ---------------------------------------------------------------------------
;;; git config reader — no fork, cl-inix parses .git/config in-process
;;; ---------------------------------------------------------------------------

(defun read-git-config ()
  "Parse .git/config in CWD and return meta.* values as a plist.
   Uses cl-inix:read — no subprocess, no fork (NASA Power of 10 rule 6)."
  (let* ((config-path (merge-pathnames #P".git/config" (uiop:getcwd)))
         (config      (cl-inix:read config-path))
         (meta        (cdr (assoc "meta" config :test #'string=))))
    (unless meta
      (error "No [meta] section in .git/config.~%~
              Set required keys:~%~
                git config meta.type        <c99-binary|c99-header|lisp-actor|shell-bats|quadlet-stack>~%~
                git config meta.application <name>~%~
                git config meta.role        <role>~%~
                git config meta.version     <semver>~%~
                git config meta.branch      <main|master|develop>"))
    (flet ((required (key)
             (or (cdr (assoc key meta :test #'string=))
                 (error "meta.~A not set in .git/config" key))))
      (list :type        (required "type")
            :application (required "application")
            :role        (required "role")
            :version     (required "version")
            :branch      (required "branch")
            :licence     (or (cdr (assoc "licence" meta :test #'string=))
                             "bsd-2-clause")))))

;;; ---------------------------------------------------------------------------
;;; Dispatch table
;;; ---------------------------------------------------------------------------

(defparameter *scaffold-dispatch*
  '(("c99-binary"    . c99-binary-scaffold)
    ("c99-header"    . c99-header-scaffold)
    ("lisp-actor"    . lisp-actor-scaffold)
    ("shell-bats"    . shell-bats-scaffold)
    ("quadlet-stack" . quadlet-stack-scaffold)))

;;; ---------------------------------------------------------------------------
;;; Apply governance properties via Consfigurator :local connection
;;; ---------------------------------------------------------------------------

(defun apply-governance (scaffold-sym config)
  "Apply SCAFFOLD-SYM property combinator to the local checkout via
   Consfigurator deploy-these* with a :local connection.
   No defhost required — make-host constructs a minimal anonymous host."
  (consfigurator:deploy-these*
    '((:local))
    (consfigurator:make-host
      :hostattrs `(:hostname (,(uiop:hostname))))
    (consfigurator:make-propspec
      :propspec `(consfigurator:eseqprops
                   (,scaffold-sym ,config)))))

;;; ---------------------------------------------------------------------------
;;; Entry point
;;; ---------------------------------------------------------------------------

(defun main ()
  (handler-case
      (let* ((config (read-git-config))
             (type   (getf config :type))
             (entry  (assoc type *scaffold-dispatch* :test #'string=)))
        (unless entry
          (error "Unknown meta.type: ~S~%Valid: ~{~A~^, ~}"
                 type (mapcar #'car *scaffold-dispatch*)))
        (format t "~&[dps-meta] ~A ~A (~A)~%"
                (getf config :application)
                (getf config :version)
                type)
        ;; 1. Governance files + identity headers via Consfigurator :local
        (apply-governance (cdr entry) config)
        ;; 2. .github/workflows/ci.yml via 40ants/CI
        (generate-ci-workflow config)
        (format t "~&[dps-meta] Done.~%")
        (uiop:quit 0))
    (error (e)
      (format *error-output* "~&[dps-meta] ERROR: ~A~%" e)
      (uiop:quit 1))))
