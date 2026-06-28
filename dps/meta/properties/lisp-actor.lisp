;;;; SPDX-License-Identifier: BSD-2-Clause
(defpackage #:dps.meta.properties.lisp-actor
  (:use #:cl)
  (:import-from #:dps.meta.properties.common #:net-matrix-governance #:write-generated-file)
  (:import-from #:dps.meta.identity.lisp #:matrix-id-lisp-content)
  (:export #:lisp-actor-scaffold))
(in-package #:dps.meta.properties.lisp-actor)
(defun application->package-name (app) (substitute #\. #\- app :count 1))
(defun lisp-actor-scaffold (config)
  (net-matrix-governance config)
  (write-generated-file "src/matrix-id.lisp"
    (matrix-id-lisp-content
      (application->package-name (getf config :application))
      (getf config :application) (getf config :role)
      (getf config :version) "daplanet" (getf config :licence))))
