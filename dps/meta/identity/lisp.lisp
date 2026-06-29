;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/identity/lisp.lisp
;;;;
;;;; SBCL identity module generation for dps/meta.
;;;; Delegates to dps.meta.identity.upstream — the canonical module is
;;;; fetched from https://cispec.org/spec/matrix-id.lisp at scaffold time.
;;;;
;;;; Public API unchanged: (matrix-id-lisp-content package-name application
;;;;                                                 role version organisation
;;;;                                                 licence)
;;;; Callers in dps/meta/properties/lisp-actor.lisp require no changes.

(defpackage #:dps.meta.identity.lisp
  (:use #:cl #:dps.meta.identity.upstream)
  (:export #:matrix-id-lisp-content))

(in-package #:dps.meta.identity.lisp)

(defun matrix-id-lisp-content (package-name application role version
                                organisation licence)
  "Return the content for src/matrix-id.lisp in the target repo.

   Fetches the canonical module from https://cispec.org/spec/matrix-id.lisp.
   The module reads CISPEC_* from the environment at load time via env-or,
   so no source interpolation is required.

   PACKAGE-NAME, ROLE, ORGANISATION, and LICENCE are accepted for API
   compatibility. PACKAGE-NAME and ROLE are recorded in the generated
   header comment. The module's own defpackage is org.cispec.matrix-id
   (canonical); the target project imports from it."
  (declare (ignore role organisation licence))
  (fetch-matrix-id-lisp :note-application application))
