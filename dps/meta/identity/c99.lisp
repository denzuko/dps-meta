;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/identity/c99.lisp
;;;;
;;;; C99 identity header generation for dps/meta.
;;;; Delegates to dps.meta.identity.upstream — the canonical header is
;;;; fetched from https://cispec.org/spec/matrix_id.h at scaffold time.
;;;;
;;;; Public API unchanged: (matrix-id-h-content application role version
;;;;                                              organisation licence)
;;;; Callers in dps/meta/properties/c99-binary.lisp and c99-header.lisp
;;;; require no changes.

(defpackage #:dps.meta.identity.c99
  (:use #:cl #:dps.meta.identity.upstream)
  (:export #:matrix-id-h-content))

(in-package #:dps.meta.identity.c99)

(defun matrix-id-h-content (application role version organisation licence)
  "Return the content for matrix_id.h in the target repo.

   Fetches the canonical header from https://cispec.org/spec/matrix_id.h
   and prepends a generated preamble with APPLICATION, ORGANISATION, and
   VERSION pre-populated as default defines.

   ROLE and LICENCE are accepted for API compatibility; ROLE is recorded
   in the preamble comment, LICENCE is validated but the header itself is
   always BSD-2-Clause (the cispec canonical licence)."
  (when (and licence
             (not (string-equal licence "bsd-2-clause"))
             (not (string-equal licence "BSD-2-Clause")))
    (warn "dps/meta: matrix_id.h is BSD-2-Clause regardless of repo licence (~A); ~
           the generated header will carry the BSD-2-Clause SPDX identifier."
          licence))
  (fetch-matrix-id-h application role version
                      :organisation organisation
                      :licence      "BSD-2-Clause"))
