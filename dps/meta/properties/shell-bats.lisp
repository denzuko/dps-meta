;;;; SPDX-License-Identifier: BSD-2-Clause
(defpackage #:dps.meta.properties.shell-bats
  (:use #:cl #:consfigurator)
  (:import-from #:dps.meta.properties.common #:net-matrix-governance)
  (:export #:shell-bats-scaffold))
(in-package #:dps.meta.properties.shell-bats)
(defproplist shell-bats-scaffold :lisp (config)
  (:desc (format nil "shell-bats scaffold for ~A" (getf config :application)))
  (net-matrix-governance config))
