;;;; SPDX-License-Identifier: BSD-2-Clause
(defpackage #:dps.meta.properties.lisp-actor
  (:use #:cl #:consfigurator)
  (:import-from #:consfigurator.property.file #:has-content)
  (:import-from #:dps.meta.properties.common  #:net-matrix-governance)
  (:import-from #:dps.meta.identity.lisp      #:matrix-id-lisp-content)
  (:export #:lisp-actor-scaffold))
(in-package #:dps.meta.properties.lisp-actor)
(defun app->pkg (app) (substitute #\. #\- app :count 1))
(defproplist lisp-actor-scaffold :lisp (config)
  (:desc (format nil "lisp-actor scaffold for ~A" (getf config :application)))
  (net-matrix-governance config)
  (has-content "src/matrix-id.lisp"
    (matrix-id-lisp-content
      (app->pkg (getf config :application)) (getf config :application)
      (getf config :role) (getf config :version) "daplanet" (getf config :licence))))
