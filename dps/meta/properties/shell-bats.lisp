;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/properties/shell-bats.lisp
;;;;
;;;; shell-bats repos: common governance only.
;;;; No identity header — shell scripts carry identity via comments.

(defpackage #:dps.meta.properties.shell-bats
  (:use #:cl #:consfigurator)
  (:import-from #:dps.meta.properties.common #:net-matrix-governance)
  (:export #:shell-bats-scaffold))

(in-package #:dps.meta.properties.shell-bats)

(defproplist shell-bats-scaffold (config)
  "Full scaffold for a shell-bats repo: common governance only."
  (:desc (format nil "shell-bats scaffold for ~A" (getf config :application)))
  (net-matrix-governance config))
