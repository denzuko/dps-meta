;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/ci/slsa-job.lisp
;;;;
;;;; 40ants/CI custom job class that emits the SLSA Level 3 provenance triple:
;;;;   1. build-job      — compiles the artifact, uploads to GitHub Actions cache
;;;;   2. provenance-job — slsa-framework/slsa-github-generator generic builder
;;;;   3. verify-job     — slsa-verifier confirms provenance before any release gate
;;;;
;;;; The three jobs are always emitted together; callers use SLSA-JOB, not the
;;;; individual sub-jobs.  40ants/CI handles YAML serialisation.

(defpackage #:dps.meta.ci.slsa
  (:use #:cl #:40ants-ci/jobs/job)
  (:export #:slsa-job
           #:slsa-job-artifact-name
           #:slsa-job-build-command
           #:slsa-job-runner))

(in-package #:dps.meta.ci.slsa)

;;; ---------------------------------------------------------------------------
;;; Class
;;; ---------------------------------------------------------------------------

(defclass slsa-job (job)
  ((artifact-name
    :initarg :artifact-name
    :reader slsa-job-artifact-name
    :documentation "Name of the built artifact uploaded to the Actions cache.")
   (build-command
    :initarg :build-command
    :initform "qlot exec ros build"
    :reader slsa-job-build-command
    :documentation "Shell command that produces the artifact.
    Default is the dps-meta standard: qlot exec ros build.
    C99 repos override with: nob")
   (runner
    :initarg :runner
    :initform "ubuntu-24.04"
    :reader slsa-job-runner
    :documentation "GitHub Actions runner image. Pinned; never ubuntu-latest."))
  (:documentation
   "Emits a three-job SLSA Level 3 provenance workflow:
    build → slsa-github-generator provenance → slsa-verifier gate.
    The YAML is emitted into .github/workflows/slsa.yml by the parent
    Consfigurator property."))

;;; ---------------------------------------------------------------------------
;;; 40ants/CI protocol implementation
;;; ---------------------------------------------------------------------------

(defmethod 40ants-ci/jobs/job:job-needs ((job slsa-job))
  "Provenance and verify jobs depend on build; return dependency graph."
  ;; 40ants/CI interprets this as the needs: key in the emitted YAML.
  '(("provenance" . ("build"))
    ("verify"     . ("provenance"))))

(defmethod 40ants-ci/jobs/job:job-steps ((job slsa-job))
  "Return the step sequences for all three sub-jobs as an alist."
  (list
   ;; --- build sub-job ---
   (cons "build"
         (list
          `(:name "Checkout"
            :uses "actions/checkout@v4"
            :with (:fetch-depth 0))
          `(:name "Setup SBCL + Roswell"
            :uses "40ants/setup-lisp@v4"
            :with (:lisp "sbcl-bin"))
          `(:name "Install qlot"
            :run "ros install qlot")
          `(:name "Install dependencies"
            :run "qlot install")
          `(:name "Build artifact"
            :run ,(slsa-job-build-command job)
            :id "build")
          `(:name "Upload artifact"
            :uses "actions/upload-artifact@v4"
            :with (:name ,(slsa-job-artifact-name job)
                   :path ,(slsa-job-artifact-name job)))))
   ;; --- provenance sub-job ---
   ;; Uses the SLSA generic generator; permissions and secrets are required.
   (cons "provenance"
         (list
          `(:name "Generate SLSA provenance"
            :uses "slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2"
            :with (:base64-subjects "${{ needs.build.outputs.hashes }}"
                   :upload-assets "true"))))
   ;; --- verify sub-job ---
   (cons "verify"
         (list
          `(:name "Checkout"
            :uses "actions/checkout@v4")
          `(:name "Download artifact"
            :uses "actions/download-artifact@v4"
            :with (:name ,(slsa-job-artifact-name job)))
          `(:name "Download provenance"
            :uses "actions/download-artifact@v4"
            :with (:name ,(format nil "~A.intoto.jsonl"
                                  (slsa-job-artifact-name job))))
          `(:name "Verify provenance"
            :run ,(format nil
                    "slsa-verifier verify-artifact ~A \\~%~
                     --provenance-path ~A.intoto.jsonl \\~%~
                     --source-uri github.com/${{ github.repository }}"
                    (slsa-job-artifact-name job)
                    (slsa-job-artifact-name job)))))))

(defmethod 40ants-ci/jobs/job:job-permissions ((job slsa-job))
  "SLSA generic generator requires id-token write and contents write."
  '((:id-token . "write")
    (:contents  . "write")
    (:actions   . "read")))

(defmethod 40ants-ci/jobs/job:job-runner ((job slsa-job))
  (slsa-job-runner job))
