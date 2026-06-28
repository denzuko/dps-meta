;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/ci/generate.lisp
;;;;
;;;; generate-ci-workflow: builds job descriptor list for 40ants/CI
;;;; and calls 40ants-ci/github:generate to write .github/workflows/ci.yml.
;;;;
;;;; 40ants/CI initialize-instance :around on workflow calls make-job on each
;;;; entry in :jobs. make-job expects (class-name-symbol . initargs) or a bare
;;;; class-name-symbol — it calls make-instance on the symbol.
;;;; We therefore pass job specs as (class-name :initarg val ...) plists, not
;;;; pre-built instances.

(defpackage #:dps.meta.ci.generate
  (:use #:cl)
  (:import-from #:dps.meta.ci.workflow #:dps-workflow)
  (:import-from #:dps.meta.ci.jobs
                #:opa-gate-job #:build-job #:cppcheck-job #:sbom-job
                #:slsa-provenance-job #:slsa-verify-job #:release-job
                #:build-command-for)
  (:export #:generate-ci-workflow))

(in-package #:dps.meta.ci.generate)

(defun job-specs-for (meta-type application)
  "Return a list of (class-symbol :key val ...) job descriptors for META-TYPE.
   These are consumed by 40ants/CI's make-job inside workflow initialize-instance."
  (let ((c99-p (member meta-type '("c99-binary" "c99-header") :test #'string=))
        (cdxgen-type (cdr (assoc meta-type
                                 '(("c99-binary"   . "c")
                                   ("c99-header"   . "c")
                                   ("lisp-actor"   . "generic")
                                   ("shell-bats"   . "generic")
                                   ("quadlet-stack". "generic"))
                                 :test #'string=))))
    (append
     (list
      '(opa-gate-job)
      `(build-job
         :build-command ,(build-command-for meta-type application)
         :artifact-name ,application)
      `(sbom-job :cdxgen-type ,(or cdxgen-type "generic"))
      `(slsa-provenance-job :artifact-name ,application)
      `(slsa-verify-job     :artifact-name ,application)
      `(release-job         :artifact-name ,application))
     (when c99-p
       '((cppcheck-job))))))

(defun generate-ci-workflow (config)
  "Emit .github/workflows/ci.yml into CWD via 40ants/CI."
  (let* ((meta-type   (getf config :type))
         (application (getf config :application))
         (branch      (getf config :branch))
         (wf (make-instance 'dps-workflow
               :name          (intern (string-upcase application)
                                      (find-package :dps.meta.ci.generate))
               :on-push-to    (list branch)
               :on-pull-request t
               :cache         nil
               :env           `(("REGISTRY" . "ghcr.io")
                                ("IMAGE"    . ,(format nil "ghcr.io/denzuko/~A"
                                                       application)))
               :jobs          (job-specs-for meta-type application)))
         (workflows-dir (merge-pathnames #P".github/workflows/" (uiop:getcwd)))
         (ci-path       (merge-pathnames #P"ci.yml" workflows-dir)))
    (ensure-directories-exist workflows-dir)
    (40ants-ci/github:generate wf ci-path)
    (format t "~&[dps-meta] wrote .github/workflows/ci.yml~%")))
