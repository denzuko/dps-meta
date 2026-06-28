;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/properties/common.lisp
;;;;
;;;; File writing primitives — uiop:with-output-file only.
;;;; Consfigurator belongs in the generated scaffold, not in the generator.

(defpackage #:dps.meta.properties.common
  (:use #:cl)
  (:import-from #:dps.meta.governance
                #:claude-md-content #:contributing-content #:security-content
                #:code-of-conduct-content #:support-content
                #:codeowners-content #:changelog-stub-content)
  (:import-from #:dps.meta.policy.slsa #:slsa-rego-content)
  (:export #:write-file #:net-matrix-governance))

(in-package #:dps.meta.properties.common)

(defun write-file (relative-path content)
  "Write CONTENT to RELATIVE-PATH under CWD, creating parent dirs as needed."
  (let ((target (merge-pathnames relative-path (uiop:getcwd))))
    (ensure-directories-exist target)
    (uiop:with-output-file (out target :if-exists :supersede)
      (write-string content out))
    (format t "~&[dps-meta] wrote ~A~%" relative-path)))

(defun net-matrix-governance (config)
  (write-file "CLAUDE.md"
    (claude-md-content
      (getf config :application) (getf config :type)
      (getf config :version)     (getf config :branch)
      (getf config :licence)))
  (write-file "CONTRIBUTING.md"  (contributing-content   (getf config :application)))
  (write-file "SECURITY.md"      (security-content       (getf config :application)))
  (write-file "CODE_OF_CONDUCT.md" (code-of-conduct-content))
  (write-file "SUPPORT.md"       (support-content        (getf config :application)))
  (write-file ".github/CODEOWNERS" (codeowners-content))
  (write-file "CHANGELOG.md"
    (changelog-stub-content (getf config :application) (getf config :version)))
  (write-file "policy/slsa.rego" (slsa-rego-content      (getf config :application))))
