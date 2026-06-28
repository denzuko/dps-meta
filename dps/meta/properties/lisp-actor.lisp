;;;; SPDX-License-Identifier: BSD-2-Clause
(defpackage #:dps.meta.properties.lisp-actor
  (:use #:cl)
  (:import-from #:dps.meta.properties.common #:net-matrix-governance #:write-file)
  (:import-from #:dps.meta.identity.lisp     #:matrix-id-lisp-content)
  (:export #:lisp-actor-scaffold))
(in-package #:dps.meta.properties.lisp-actor)
(defun lisp-actor-scaffold (config)
  (net-matrix-governance config)
  (write-file "src/matrix-id.lisp"
    (matrix-id-lisp-content
      (substitute #\. #\- (getf config :application) :count 1)
      (getf config :application) (getf config :role)
      (getf config :version) "daplanet" (getf config :licence))))
