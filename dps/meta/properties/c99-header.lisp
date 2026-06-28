;;;; SPDX-License-Identifier: BSD-2-Clause
(defpackage #:dps.meta.properties.c99-header
  (:use #:cl)
  (:import-from #:dps.meta.properties.c99-binary #:c99-binary-scaffold)
  (:export #:c99-header-scaffold))
(in-package #:dps.meta.properties.c99-header)
(defun c99-header-scaffold (config) (c99-binary-scaffold config))
