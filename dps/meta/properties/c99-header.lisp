;;;; SPDX-License-Identifier: BSD-2-Clause
(defpackage #:dps.meta.properties.c99-header
  (:use #:cl #:consfigurator)
  (:import-from #:dps.meta.properties.c99-binary #:c99-binary-scaffold)
  (:export #:c99-header-scaffold))
(in-package #:dps.meta.properties.c99-header)
(defproplist c99-header-scaffold :lisp (config)
  (:desc (format nil "c99-header scaffold for ~A" (getf config :application)))
  (c99-binary-scaffold config))
