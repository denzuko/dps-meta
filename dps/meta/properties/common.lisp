;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/properties/common.lisp

(defpackage #:dps.meta.properties.common
  (:use #:cl #:consfigurator)
  (:import-from #:consfigurator.property.file #:has-content)
  (:import-from #:dps.meta.governance
                #:claude-md-content #:contributing-content #:security-content
                #:code-of-conduct-content #:support-content
                #:codeowners-content #:changelog-stub-content)
  (:import-from #:dps.meta.policy.slsa #:slsa-rego-content)
  (:export #:net-matrix-governance))

(in-package #:dps.meta.properties.common)

(defproplist net-matrix-governance :lisp (config)
  (:desc (format nil "net.matrix governance for ~A" (getf config :application)))
  (has-content "CLAUDE.md"
    (claude-md-content
      (getf config :application) (getf config :type)
      (getf config :version)     (getf config :branch)
      (getf config :licence)))
  (has-content "CONTRIBUTING.md"  (contributing-content   (getf config :application)))
  (has-content "SECURITY.md"      (security-content       (getf config :application)))
  (has-content "CODE_OF_CONDUCT.md" (code-of-conduct-content))
  (has-content "SUPPORT.md"       (support-content        (getf config :application)))
  (has-content ".github/CODEOWNERS" (codeowners-content))
  (has-content "CHANGELOG.md"
    (changelog-stub-content (getf config :application) (getf config :version)))
  (has-content "policy/slsa.rego" (slsa-rego-content      (getf config :application))))
