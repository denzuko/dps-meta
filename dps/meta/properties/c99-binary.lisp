;;;; SPDX-License-Identifier: BSD-2-Clause
(defpackage #:dps.meta.properties.c99-binary
  (:use #:cl)
  (:import-from #:dps.meta.properties.common  #:net-matrix-governance #:write-file)
  (:import-from #:dps.meta.identity.c99       #:matrix-id-h-content)
  (:import-from #:dps.meta.policy.c-quality   #:c-quality-rego-content)
  (:import-from #:dps.meta.policy.ast         #:ast-rego-content)
  (:export #:c99-binary-scaffold))
(in-package #:dps.meta.properties.c99-binary)
(defun c99-binary-scaffold (config)
  (net-matrix-governance config)
  (write-file "matrix_id.h"
    (matrix-id-h-content (getf config :application) (getf config :role)
                         (getf config :version) "daplanet" (getf config :licence)))
  (write-file "policy/c_quality.rego" (c-quality-rego-content (getf config :application)))
  (write-file "policy/ast.rego"       (ast-rego-content       (getf config :application))))
