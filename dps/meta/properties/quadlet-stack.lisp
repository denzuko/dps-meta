;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/properties/quadlet-stack.lisp
;;;;
;;;; quadlet-stack repos: common governance only.
;;;; Quadlet files carry identity via OCI image label arguments at deploy time.

(defpackage #:dps.meta.properties.quadlet-stack
  (:use #:cl #:consfigurator)
  (:import-from #:dps.meta.properties.common #:net-matrix-governance)
  (:export #:quadlet-stack-scaffold))

(in-package #:dps.meta.properties.quadlet-stack)

(defproplist quadlet-stack-scaffold (config)
  "Full scaffold for a quadlet-stack repo: common governance only."
  (:desc (format nil "quadlet-stack scaffold for ~A" (getf config :application)))
  (net-matrix-governance config))
