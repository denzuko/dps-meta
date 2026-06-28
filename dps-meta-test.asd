;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps-meta-test.asd

(defsystem "dps-meta-test"
  :description "FiveAM attestation specs for dps-meta generated output"
  :version "0.1.0"
  :author "Den Zuko <den@dapla.net>"
  :licence "BSD-2-Clause"
  :depends-on ("dps-meta"
               "fiveam")
  :components
  ((:module "dps/meta/attestation"
    :components
    ((:file "specs"))))
  :perform (test-op (op c)
             (symbol-call :fiveam :run! 'dps.meta.attestation:all)))
