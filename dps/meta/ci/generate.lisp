;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/ci/generate.lisp
;;;;
;;;; Entry point: generate-ci-workflow writes .github/workflows/ci.yml
;;;; into the target checkout using 40ants/CI — no hand-written YAML.

(defpackage #:dps.meta.ci.generate
  (:use #:cl)
  (:import-from #:40ants-ci/workflow  #:defworkflow)
  (:import-from #:40ants-ci/core      #:generate)
  (:import-from #:dps.meta.ci.workflow #:dps-workflow)
  (:import-from #:dps.meta.ci.jobs    #:make-pipeline)
  (:export #:generate-ci-workflow))

(in-package #:dps.meta.ci.generate)

(defun generate-ci-workflow (config)
  "Generate .github/workflows/ci.yml into CWD via 40ants/CI.
   CONFIG is the plist from git-config meta.* keys."
  (let* ((meta-type     (getf config :type))
         (application   (getf config :application))
         (branch        (getf config :branch))
         (jobs          (make-pipeline meta-type application))
         ;; Dynamically define the workflow class scoped to this invocation
         (wf (make-instance 'dps-workflow
                            :name    (intern (string-upcase application)
                                            (find-package :dps.meta.ci.generate))
                            :on-push-to   (list branch)
                            :on-pull-request t
                            :cache nil
                            :env `(("REGISTRY" . "ghcr.io")
                                   ("IMAGE"    . ,(format nil "ghcr.io/denzuko/~A" application)))
                            :jobs jobs))
         ;; Target path: .github/workflows/ under CWD
         (workflows-dir (merge-pathnames ".github/workflows/"
                                         (uiop:getcwd)))
         (ci-path       (merge-pathnames "ci.yml" workflows-dir)))
    (ensure-directories-exist workflows-dir)
    ;; 40ants/CI generate method writes the YAML
    (40ants-ci/github:generate wf ci-path)
    (format t "~&[dps-meta] wrote .github/workflows/ci.yml~%")))
