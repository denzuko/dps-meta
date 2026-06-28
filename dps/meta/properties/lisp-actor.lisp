;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/properties/lisp-actor.lisp
;;;;
;;;; Consfigurator defproplist: LISP-ACTOR-SCAFFOLD
;;;; Applied on top of NET-MATRIX-GOVERNANCE for lisp-actor repos.
;;;; Adds: src/matrix-id.lisp

(defpackage #:dps.meta.properties.lisp-actor
  (:use #:cl #:consfigurator #:consfigurator/property/file)
  (:import-from #:dps.meta.properties.common #:net-matrix-governance)
  (:import-from #:dps.meta.identity.lisp #:matrix-id-lisp-content)
  (:export #:lisp-actor-scaffold))

(in-package #:dps.meta.properties.lisp-actor)

(defun application->package-name (application)
  "Derive a Lisp package name from the meta.application value.
   e.g. 'dps-meta' → 'dps.meta'
   Replaces hyphens that separate major segments with dots."
  ;; Conservative: replace first hyphen only; DPS naming convention is
  ;; <org>-<app> → <org>.<app>.  Adjust if deeper nesting is needed.
  (substitute #\. #\- application :count 1))

(defproplist lisp-actor-scaffold (config)
  "Full scaffold for a lisp-actor repo: common governance + Lisp identity module."
  (:desc (format nil "lisp-actor scaffold for ~A" (getf config :application)))
  (net-matrix-governance config)
  (file:has-content "src/matrix-id.lisp"
    (matrix-id-lisp-content
      (application->package-name (getf config :application))
      (getf config :application)
      (getf config :role)
      (getf config :version)
      "daplanet"
      (getf config :licence))))
