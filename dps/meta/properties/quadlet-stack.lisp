;;;; SPDX-License-Identifier: BSD-2-Clause
(defpackage #:dps.meta.properties.quadlet-stack
  (:use #:cl)
  (:import-from #:dps.meta.properties.common #:net-matrix-governance)
  (:export #:quadlet-stack-scaffold))
(in-package #:dps.meta.properties.quadlet-stack)
(defun quadlet-stack-scaffold (config) (net-matrix-governance config))
