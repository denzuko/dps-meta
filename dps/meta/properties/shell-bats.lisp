;;;; SPDX-License-Identifier: BSD-2-Clause
(defpackage #:dps.meta.properties.shell-bats
  (:use #:cl)
  (:import-from #:dps.meta.properties.common #:net-matrix-governance)
  (:export #:shell-bats-scaffold))
(in-package #:dps.meta.properties.shell-bats)
(defun shell-bats-scaffold (config) (net-matrix-governance config))
