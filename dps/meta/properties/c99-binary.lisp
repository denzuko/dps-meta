;;;; SPDX-License-Identifier: BSD-2-Clause
(defpackage #:dps.meta.properties.c99-binary
  (:use #:cl #:consfigurator)
  (:import-from #:consfigurator.property.file #:has-content)
  (:import-from #:dps.meta.properties.common  #:net-matrix-governance)
  (:import-from #:dps.meta.identity.c99       #:matrix-id-h-content)
  (:import-from #:dps.meta.policy.c-quality   #:c-quality-rego-content)
  (:import-from #:dps.meta.policy.ast         #:ast-rego-content)
  (:export #:c99-binary-scaffold))
(in-package #:dps.meta.properties.c99-binary)
(defproplist c99-binary-scaffold :lisp (config)
  (:desc (format nil "c99-binary scaffold for ~A" (getf config :application)))
  (net-matrix-governance config)
  (has-content "matrix_id.h"
    (matrix-id-h-content (getf config :application) (getf config :role)
                         (getf config :version) "daplanet" (getf config :licence)))
  (has-content "policy/c_quality.rego" (c-quality-rego-content (getf config :application)))
  (has-content "policy/ast.rego"       (ast-rego-content       (getf config :application))))
