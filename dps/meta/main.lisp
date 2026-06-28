;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/main.lisp
;;;;
;;;; Entry point. Reads meta.* from .git/config via cl-inix (no fork),
;;;; applies Consfigurator defproplist for governance files,
;;;; then calls 40ants/CI to emit .github/workflows/ci.yml.

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
;;; git config reader — no fork, parse .git/config directly via cl-inix
;;; ---------------------------------------------------------------------------

(defun read-git-config ()
  "Parse .git/config in CWD and return the meta section as a plist.
   Signals an error if the file is missing or meta.* keys are absent.
   No subprocess spawned — cl-inix reads the ini file in-process."
  (let* ((config-path (merge-pathnames #P".git/config" (uiop:getcwd)))
         (_ (unless (uiop:file-exists-p config-path)
              (error "No .git/config found — run dps-meta inside a git checkout")))
         (config      (cl-inix:read config-path))
         (meta        (cdr (assoc "meta" config :test #'string=))))
    (declare (ignore _))
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
;;; Dispatch
;;; ---------------------------------------------------------------------------

(defparameter *scaffold-dispatch*
  '(("c99-binary"    . c99-binary-scaffold)
    ("c99-header"    . c99-header-scaffold)
    ("lisp-actor"    . lisp-actor-scaffold)
    ("shell-bats"    . shell-bats-scaffold)
    ("quadlet-stack" . quadlet-stack-scaffold)))

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
        ;; 1. Governance files via Consfigurator localhd (:local connection)
        (consfigurator:localhd
          (funcall (symbol-function (cdr entry)) config))
        ;; 2. CI workflow via 40ants/CI
        (generate-ci-workflow config)
        (format t "~&[dps-meta] Done.~%")
        (uiop:quit 0))
    (error (e)
      (format *error-output* "~&[dps-meta] ERROR: ~A~%" e)
      (uiop:quit 1))))
