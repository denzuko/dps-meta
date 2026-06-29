;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/policy/upstream.lisp
;;;;
;;;; Fetch canonical Rego gate files from https://cispec.org/gates/.
;;;; Replaces inline Rego string generation in slsa.lisp, c-quality.lisp,
;;;; and ast.lisp.
;;;;
;;;; Gate files are fetched at scaffold-generation time and written verbatim
;;;; to policy/ in the target repo. dps/meta no longer owns gate content.
;;;;
;;;; The cimatrix gate bundle cache (~/.cache/cimatrix/gates/) is used when
;;;; available and fresh (< 24h), falling back to a direct cispec.org fetch.
;;;; This means a machine with cimatrix installed gets offline-capable gate
;;;; fetching for free.

(defpackage #:dps.meta.policy.upstream
  (:use #:cl)
  (:import-from #:dps.meta.identity.upstream
                #:*cispec-base-url*
                #:*fetch-timeout-seconds*
                #:fetch-url)
  (:export #:fetch-gate
           #:gate-url
           #:*cimatrix-cache-dir*))

(in-package #:dps.meta.policy.upstream)

(defparameter *cimatrix-cache-dir*
  (merge-pathnames #p".cache/cimatrix/gates/" (user-homedir-pathname))
  "cimatrix gate bundle cache directory. Used when fresh (< 24h old).")

(defparameter *cache-ttl-seconds* (* 24 60 60)
  "Gate cache TTL matching cimatrix's own default.")

;;; ----------------------------------------------------------------
;;; Gate URL
;;; ----------------------------------------------------------------

(defun gate-url (gate-path)
  "Return the full cispec.org URL for GATE-PATH (e.g. \"slsa/provenance.rego\")."
  (str:concat *cispec-base-url* "/gates/" gate-path))

;;; ----------------------------------------------------------------
;;; Cache probe
;;; ----------------------------------------------------------------

(defun cached-gate-path (gate-path)
  "Return the local cimatrix cache path for GATE-PATH, or NIL if absent/stale."
  (let ((path (merge-pathnames (pathname gate-path) *cimatrix-cache-dir*)))
    (when (probe-file path)
      (let* ((mtime (file-write-date path))
             (age   (- (get-universal-time) mtime)))
        (when (< age *cache-ttl-seconds*)
          path)))))

(defun read-file-string (path)
  "Return the contents of PATH as a string."
  (with-open-file (f path :direction :input)
    (let ((buf (make-string (file-length f))))
      (read-sequence buf f)
      buf)))

;;; ----------------------------------------------------------------
;;; fetch-gate — cache-first, then cispec.org
;;; ----------------------------------------------------------------

(defun fetch-gate (gate-path)
  "Return the Rego gate source for GATE-PATH as a string.

   Checks the cimatrix gate bundle cache first. If absent or stale,
   fetches from https://cispec.org/gates/<gate-path>.

   GATE-PATH examples:
     \"cispec/attribution.rego\"
     \"slsa/provenance.rego\"
     \"c-quality/attribution.rego\"
     \"sbom/cyclonedx.rego\"
     \"containers/quadlet.rego\"
     \"ast/forbidden-calls.rego\""
  (let ((cached (cached-gate-path gate-path)))
    (if cached
        (read-file-string cached)
        (let* ((url      (gate-url gate-path))
               ;; Gate pages are Hugo Markdown — extract the rego block
               (markdown (fetch-url url))
               (rego     (extract-rego-block markdown)))
          (or rego
              ;; Fallback: try the raw .rego path directly (future: raw.cispec.org)
              (fetch-url (str:concat *cispec-base-url* "/gates/raw/" gate-path)))))))

(defun extract-rego-block (markdown-body)
  "Extract the first ```rego ... ``` fenced code block from MARKDOWN-BODY."
  (cl-ppcre:register-groups-bind (code)
      ("(?s)```rego\\n(.*?)```" markdown-body)
    code))
