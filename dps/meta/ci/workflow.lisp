;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/ci/workflow.lisp
;;;;
;;;; DPS workflow subclass that adds tag-push trigger to make-triggers,
;;;; enabling a single ci.yml to cover both PR/push quality gates and
;;;; release-tag SLSA provenance in one workflow file.

(defpackage #:dps.meta.ci.workflow
  (:use #:cl)
  (:import-from #:40ants-ci/workflow
                #:workflow
                #:make-triggers
                #:on-push-to
                #:on-pull-request)
  (:export #:dps-workflow))

(in-package #:dps.meta.ci.workflow)

(defclass dps-workflow (workflow)
  ()
  (:documentation
   "Workflow subclass that emits push+PR+tag triggers.
    Quality jobs run on push/PR; SLSA jobs self-gate on tag ref."))

(defmethod make-triggers ((w dps-workflow))
  (append
   ;; push to default branch
   (when (on-push-to w)
     `(("push" . (("branches" . ,(on-push-to w))
                  ("tags"     . ("v*"))))))
   ;; pull requests
   (when (on-pull-request w)
     '(("pull_request" . :null)))))
