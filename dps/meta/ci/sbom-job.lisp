;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/ci/sbom-job.lisp
;;;;
;;;; 40ants/CI custom job class that:
;;;;   1. Runs cdxgen to produce a CycloneDX SBOM (JSON format)
;;;;   2. Runs osv-scanner against the SBOM to gate on known CVEs
;;;;   3. Uploads the SBOM as a workflow artifact
;;;;
;;;; cdxgen type is derived from the repo meta.type git-config key, passed
;;;; in at construction time by the Consfigurator property combinator.

(defpackage #:dps.meta.ci.sbom
  (:use #:cl #:40ants-ci/jobs/job)
  (:export #:sbom-job
           #:sbom-job-cdxgen-type
           #:sbom-job-runner))

(in-package #:dps.meta.ci.sbom)

;;; ---------------------------------------------------------------------------
;;; cdxgen type mapping — meta.type → cdxgen --type argument
;;; ---------------------------------------------------------------------------

(defparameter *cdxgen-type-map*
  '(("c99-binary"     . "c")
    ("c99-header"     . "c")
    ("lisp-actor"     . "generic")   ;; cdxgen has no native Lisp type; generic + qlot.lock
    ("shell-bats"     . "generic")
    ("quadlet-stack"  . "generic"))
  "Maps meta.type git-config values to cdxgen --type arguments.")

(defun cdxgen-type-for (meta-type)
  "Return the cdxgen --type string for META-TYPE."
  (or (cdr (assoc meta-type *cdxgen-type-map* :test #'string=))
      "generic"))

;;; ---------------------------------------------------------------------------
;;; Class
;;; ---------------------------------------------------------------------------

(defclass sbom-job (job)
  ((cdxgen-type
    :initarg :cdxgen-type
    :initform "generic"
    :reader sbom-job-cdxgen-type
    :documentation "cdxgen --type argument, derived from meta.type.")
   (runner
    :initarg :runner
    :initform "ubuntu-24.04"
    :reader sbom-job-runner))
  (:documentation
   "Generates a CycloneDX SBOM via cdxgen, scans it with osv-scanner,
    and uploads the SBOM artifact.  CVE gate: osv-scanner exits non-zero
    if any vulnerability at CRITICAL or HIGH severity is found."))

;;; ---------------------------------------------------------------------------
;;; Constructor helper
;;; ---------------------------------------------------------------------------

(defun make-sbom-job (meta-type &key (runner "ubuntu-24.04"))
  "Construct an SBOM-JOB with the correct cdxgen type for META-TYPE."
  (make-instance 'sbom-job
                 :cdxgen-type (cdxgen-type-for meta-type)
                 :runner runner))

;;; ---------------------------------------------------------------------------
;;; 40ants/CI protocol
;;; ---------------------------------------------------------------------------

(defmethod 40ants-ci/jobs/job:job-steps ((job sbom-job))
  (list
   `(:name "Checkout"
     :uses "actions/checkout@v4")
   `(:name "Setup Node.js for cdxgen"
     :uses "actions/setup-node@v4"
     :with (:node-version "20"))
   `(:name "Install cdxgen"
     :run "npm install -g @cyclonedx/cdxgen")
   `(:name "Generate CycloneDX SBOM"
     :run ,(format nil
             "cdxgen --type ~A --output sbom.json ."
             (sbom-job-cdxgen-type job)))
   `(:name "Validate SBOM schema"
     :run "cdxgen --validate sbom.json")
   `(:name "Install osv-scanner"
     :run "curl -sSfL https://raw.githubusercontent.com/google/osv-scanner/main/scripts/install.sh | sh")
   `(:name "Scan SBOM for CVEs"
     :run "osv-scanner --sbom sbom.json --format table")
   `(:name "Upload SBOM artifact"
     :if "always()"
     :uses "actions/upload-artifact@v4"
     :with (:name "sbom.json"
            :path "sbom.json"))))

(defmethod 40ants-ci/jobs/job:job-runner ((job sbom-job))
  (sbom-job-runner job))

(defmethod 40ants-ci/jobs/job:job-permissions ((job sbom-job))
  '((:contents . "read")))
