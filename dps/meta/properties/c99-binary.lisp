;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/properties/c99-binary.lisp
;;;;
;;;; Consfigurator defproplist: C99-BINARY-SCAFFOLD
;;;; Applied on top of NET-MATRIX-GOVERNANCE for c99-binary repos.
;;;; Adds: matrix_id.h, policy/c_quality.rego, policy/ast.rego

(defpackage #:dps.meta.properties.c99-binary
  (:use #:cl #:consfigurator #:consfigurator/property/file)
  (:import-from #:dps.meta.properties.common #:net-matrix-governance)
  (:import-from #:dps.meta.identity.c99 #:matrix-id-h-content)
  (:import-from #:dps.meta.policy.c-quality #:c-quality-rego-content)
  (:import-from #:dps.meta.policy.ast #:ast-rego-content)
  (:export #:c99-binary-scaffold))

(in-package #:dps.meta.properties.c99-binary)

(defproplist c99-binary-scaffold (config)
  "Full scaffold for a c99-binary repo: common governance + C99 identity + C99 Rego gates."
  (:desc (format nil "c99-binary scaffold for ~A" (getf config :application)))
  (net-matrix-governance config)
  (file:has-content "matrix_id.h"
    (matrix-id-h-content
      (getf config :application)
      (getf config :role)
      (getf config :version)
      "daplanet"
      (getf config :licence)))
  (file:has-content "policy/c_quality.rego"
    (c-quality-rego-content (getf config :application)))
  (file:has-content "policy/ast.rego"
    (ast-rego-content (getf config :application))))
