;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/properties/c99-header.lisp
;;;;
;;;; c99-header is identical to c99-binary for scaffolding purposes;
;;;; the distinction matters to the build system (nob.c target), not to
;;;; the governance generator.

(defpackage #:dps.meta.properties.c99-header
  (:use #:cl #:consfigurator #:consfigurator/property/file)
  (:import-from #:dps.meta.properties.c99-binary #:c99-binary-scaffold)
  (:export #:c99-header-scaffold))

(in-package #:dps.meta.properties.c99-header)

(defproplist c99-header-scaffold (config)
  "Full scaffold for a c99-header repo. Identical governance to c99-binary."
  (:desc (format nil "c99-header scaffold for ~A" (getf config :application)))
  (c99-binary-scaffold config))
