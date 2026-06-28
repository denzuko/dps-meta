;;;; SPDX-License-Identifier: BSD-2-Clause
(defpackage #:dps.meta.properties.quadlet-stack
  (:use #:cl #:consfigurator)
  (:import-from #:dps.meta.properties.common #:net-matrix-governance)
  (:export #:quadlet-stack-scaffold))
(in-package #:dps.meta.properties.quadlet-stack)
(defproplist quadlet-stack-scaffold :lisp (config)
  (:desc (format nil "quadlet-stack scaffold for ~A" (getf config :application)))
  (net-matrix-governance config))
