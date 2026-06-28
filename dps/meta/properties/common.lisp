;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/properties/common.lisp
;;;;
;;;; File writing for all repo types.
;;;; Uses plain uiop — no consfigurator dependency.
;;;; write-generated-file is the single primitive; all combinators use it.

(defpackage #:dps.meta.properties.common
  (:use #:cl)
  (:import-from #:dps.meta.governance
                #:claude-md-content
                #:contributing-content
                #:security-content
                #:code-of-conduct-content
                #:support-content
                #:codeowners-content
                #:changelog-stub-content)
  (:import-from #:dps.meta.policy.slsa #:slsa-rego-content)
  (:export #:write-generated-file
           #:net-matrix-governance))

(in-package #:dps.meta.properties.common)

(defun write-generated-file (relative-path content)
  "Write CONTENT string to RELATIVE-PATH under CWD, creating directories as needed."
  (let* ((target (merge-pathnames relative-path (uiop:getcwd))))
    (ensure-directories-exist target)
    (uiop:with-output-file (out target :if-exists :supersede)
      (write-string content out))
    (format t "~&[dps-meta] wrote ~A~%" relative-path)))

(defun net-matrix-governance (config)
  "Write all common governance files into CWD.
   CONFIG is a plist of git-config values."
  (write-generated-file "CLAUDE.md"
    (claude-md-content
      (getf config :application) (getf config :type)
      (getf config :version)     (getf config :branch)
      (getf config :licence)))
  (write-generated-file "CONTRIBUTING.md"
    (contributing-content (getf config :application)))
  (write-generated-file "SECURITY.md"
    (security-content (getf config :application)))
  (write-generated-file "CODE_OF_CONDUCT.md"
    (code-of-conduct-content))
  (write-generated-file "SUPPORT.md"
    (support-content (getf config :application)))
  (write-generated-file ".github/CODEOWNERS"
    (codeowners-content))
  (write-generated-file "CHANGELOG.md"
    (changelog-stub-content (getf config :application) (getf config :version)))
  (write-generated-file "policy/slsa.rego"
    (slsa-rego-content (getf config :application))))
