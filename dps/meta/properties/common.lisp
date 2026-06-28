;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/properties/common.lisp
;;;;
;;;; Consfigurator defproplist: NET-MATRIX-GOVERNANCE
;;;; Applied to every repo type. Writes all governance files and both
;;;; CI/CD workflows into the local checkout via :local connection.
;;;;
;;;; Connection type: :local only. Never :ssh, never defhost.
;;;; File writes: via consfigurator/file:has-content property only.
;;;; No YAML string surgery. No heredoc insertion.

(defpackage #:dps.meta.properties.common
  (:use #:cl #:consfigurator #:consfigurator/property/file)
  (:import-from #:dps.meta.governance
                #:claude-md-content
                #:contributing-content
                #:security-content
                #:code-of-conduct-content
                #:support-content
                #:codeowners-content
                #:changelog-stub-content)
  (:import-from #:dps.meta.policy.slsa #:slsa-rego-content)
  (:export #:net-matrix-governance))

(in-package #:dps.meta.properties.common)

;;; ---------------------------------------------------------------------------
;;; Property combinator
;;; ---------------------------------------------------------------------------

(defproplist net-matrix-governance (config)
  "Write all common governance and CI/CD files into the target checkout.
   CONFIG is a plist of git-config values:
     :application  — meta.application
     :role         — meta.role
     :version      — meta.version
     :branch       — meta.branch
     :licence      — meta.licence
     :type         — meta.type
   All file writes use consfigurator file:has-content; no string surgery."
  (:desc (format nil "net.matrix governance scaffold for ~A"
                 (getf config :application)))
  ;; --- Governance documents ---
  (file:has-content "CLAUDE.md"
    (claude-md-content
      (getf config :application)
      (getf config :type)
      (getf config :version)
      (getf config :branch)
      (getf config :licence)))
  (file:has-content "CONTRIBUTING.md"
    (contributing-content (getf config :application)))
  (file:has-content "SECURITY.md"
    (security-content (getf config :application)))
  (file:has-content "CODE_OF_CONDUCT.md"
    (code-of-conduct-content))
  (file:has-content "SUPPORT.md"
    (support-content (getf config :application)))
  (file:has-content ".github/CODEOWNERS"
    (codeowners-content))
  (file:has-content "CHANGELOG.md"
    (changelog-stub-content
      (getf config :application)
      (getf config :version)))
  ;; --- Rego policy ---
  (file:has-content "policy/slsa.rego"
    (slsa-rego-content (getf config :application))))
