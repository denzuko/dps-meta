;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps-meta.asd

(defsystem "dps-meta"
  :description "Standards scaffolding generator for the denzuko GitHub organisation"
  :version "0.1.0"
  :author "Den Zuko <den@dapla.net>"
  :licence "BSD-2-Clause"
  :depends-on ("consfigurator"
               "40ants-ci"
               "fiveam"
               "uiop")
  :components
  ((:module "dps/meta/policy"
    :components
    ((:file "slsa")
     (:file "c-quality")
     (:file "ast")))
   (:module "dps/meta/identity"
    :components
    ((:file "c99")
     (:file "lisp")))
   (:module "dps/meta/governance"
    :components
    ((:file "templates")))
   (:module "dps/meta/ci"
    :components
    ((:file "slsa-job")
     (:file "opa-gate-job")
     (:file "sbom-job")))
   (:module "dps/meta/properties"
    :depends-on ("dps/meta/policy"
                 "dps/meta/identity"
                 "dps/meta/governance")
    :components
    ((:file "common")
     (:file "c99-binary"  :depends-on ("common"))
     (:file "c99-header"  :depends-on ("c99-binary"))
     (:file "lisp-actor"  :depends-on ("common"))
     (:file "shell-bats"  :depends-on ("common"))
     (:file "quadlet-stack" :depends-on ("common"))))
   (:module "dps/meta"
    :depends-on ("dps/meta/properties"
                 "dps/meta/ci")
    :components
    ((:file "main"))))
  :build-operation "program-op"
  :build-pathname "dps-meta"
  :entry-point "dps.meta:main")
