;;;; SPDX-License-Identifier: BSD-2-Clause
(defsystem "dps-meta"
  :description "Standards scaffolding generator for the denzuko GitHub organisation"
  :version "0.1.1"
  :author "Den Zuko <den@dapla.net>"
  :licence "BSD-2-Clause"
  :depends-on ("uiop" "cl-inix" "40ants-ci")
  :components
  ((:module "dps/meta/ci"
    :components
    ((:file "workflow")
     (:file "jobs"     :depends-on ("workflow"))
     (:file "generate" :depends-on ("jobs"))))
   (:module "dps/meta/policy"
    :components
    ((:file "slsa") (:file "c-quality") (:file "ast")))
   (:module "dps/meta/identity"
    :components
    ((:file "c99") (:file "lisp")))
   (:module "dps/meta/governance"
    :components
    ((:file "templates")))
   (:module "dps/meta/properties"
    :depends-on ("dps/meta/ci" "dps/meta/policy"
                 "dps/meta/identity" "dps/meta/governance")
    :components
    ((:file "common")
     (:file "c99-binary"    :depends-on ("common"))
     (:file "c99-header"    :depends-on ("c99-binary"))
     (:file "lisp-actor"    :depends-on ("common"))
     (:file "shell-bats"    :depends-on ("common"))
     (:file "quadlet-stack" :depends-on ("common"))))
   (:module "dps/meta"
    :depends-on ("dps/meta/properties")
    :components
    ((:file "main"))))
  :build-operation "program-op"
  :build-pathname "dps-meta"
  :entry-point "dps.meta:main")
