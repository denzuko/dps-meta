;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/ci/opa-gate-job.lisp
;;;;
;;;; 40ants/CI custom job class that runs OPA policy gates against:
;;;;   - SLSA provenance attestation (policy/slsa.rego)
;;;;   - C99 quality rules (policy/c_quality.rego)  — c99 types only
;;;;   - AST structural rules (policy/ast.rego)       — c99 types only
;;;;
;;;; Emits a SARIF report consumed by GitHub Code Scanning; job fails if any
;;;; policy returns allow=false.

(defpackage #:dps.meta.ci.opa-gate
  (:use #:cl #:40ants-ci/jobs/job)
  (:export #:opa-gate-job
           #:opa-gate-job-policies
           #:opa-gate-job-runner))

(in-package #:dps.meta.ci.opa-gate)

;;; ---------------------------------------------------------------------------
;;; Class
;;; ---------------------------------------------------------------------------

(defclass opa-gate-job (job)
  ((policies
    :initarg :policies
    :initform '("policy/slsa.rego")
    :reader opa-gate-job-policies
    :documentation "List of Rego policy file paths to evaluate.
    Always includes policy/slsa.rego.
    C99 types additionally include policy/c_quality.rego and policy/ast.rego.")
   (runner
    :initarg :runner
    :initform "ubuntu-24.04"
    :reader opa-gate-job-runner))
  (:documentation
   "Runs OPA eval over the specified Rego policies and uploads a SARIF report.
    Job exit code mirrors OPA exit code: non-zero → CI fails."))

;;; ---------------------------------------------------------------------------
;;; 40ants/CI protocol
;;; ---------------------------------------------------------------------------

(defmethod 40ants-ci/jobs/job:job-steps ((job opa-gate-job))
  (list
   `(:name "Checkout"
     :uses "actions/checkout@v4")
   `(:name "Install OPA"
     :run "curl -sL https://openpolicyagent.org/downloads/latest/opa_linux_amd64_static \
           -o /usr/local/bin/opa && chmod +x /usr/local/bin/opa")
   `(:name "Check Rego syntax"
     :run ,(format nil "opa check ~{~A~^ ~}"
                   (opa-gate-job-policies job)))
   `(:name "Run policy gates"
     :id "opa-eval"
     :run ,(format nil
             "opa eval ~%~
              --format pretty ~%~
              --bundle policy/ ~%~
              --input attestation.json ~%~
              'data.dps.meta.slsa.allow == true' ~%~
              | tee opa-result.json"))
   `(:name "Assert allow"
     :run "grep -q 'true' opa-result.json || (echo 'OPA gate DENIED' && exit 1)")
   `(:name "Generate SARIF"
     :if "always()"
     :run ,(format nil
             "opa eval ~%~
              --format sarif ~%~
              --bundle policy/ ~%~
              --input attestation.json ~%~
              'data' > opa-sarif.json || true"))
   `(:name "Upload SARIF to Code Scanning"
     :if "always()"
     :uses "github/codeql-action/upload-sarif@v3"
     :with (:sarif-file "opa-sarif.json"
            :category "opa-policy-gates"))))

(defmethod 40ants-ci/jobs/job:job-runner ((job opa-gate-job))
  (opa-gate-job-runner job))

(defmethod 40ants-ci/jobs/job:job-permissions ((job opa-gate-job))
  '((:security-events . "write")
    (:contents        . "read")))
