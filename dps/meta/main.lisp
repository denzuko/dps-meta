;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/main.lisp
;;;;
;;;; Entry point for the dps-meta binary.
;;;;
;;;; Execution model:
;;;;   1. Read all meta.* git-config keys from the CWD checkout
;;;;   2. Build a config plist
;;;;   3. Dispatch to the correct Consfigurator defproplist for meta.type
;;;;   4. Apply properties via :local connection (writes into CWD)
;;;;   5. Run FiveAM attestation specs against generated output
;;;;   6. Exit 0 on success, 1 on any violation
;;;;
;;;; Run via: qlot exec ros run --load dps-meta --eval '(dps.meta:main)'
;;;; Or as compiled binary: ./dps-meta   (from qlot exec ros build)

(defpackage #:dps.meta
  (:use #:cl)
  (:import-from #:dps.meta.properties.common      #:net-matrix-governance)
  (:import-from #:dps.meta.properties.c99-binary  #:c99-binary-scaffold)
  (:import-from #:dps.meta.properties.c99-header  #:c99-header-scaffold)
  (:import-from #:dps.meta.properties.lisp-actor  #:lisp-actor-scaffold)
  (:import-from #:dps.meta.properties.shell-bats  #:shell-bats-scaffold)
  (:import-from #:dps.meta.properties.quadlet-stack #:quadlet-stack-scaffold)
  (:export #:main))

(in-package #:dps.meta)

;;; ---------------------------------------------------------------------------
;;; git-config reader
;;; ---------------------------------------------------------------------------

(defun git-config (key)
  "Read a single git-config KEY from the current repository.
   Returns the trimmed string value, or NIL if the key is unset.
   Uses uiop:run-program — no shell, no system(), no popen()."
  (handler-case
      (string-trim '(#\Space #\Newline #\Return)
                   (uiop:run-program
                     (list "git" "config" "--local" key)
                     :output :string
                     :error-output nil))
    (uiop:subprocess-error ()
      nil)))

(defun read-meta-config ()
  "Read all meta.* git-config keys and return a plist.
   Signals an error if any mandatory key is missing."
  (let* ((type        (git-config "meta.type"))
         (application (git-config "meta.application"))
         (role        (git-config "meta.role"))
         (version     (git-config "meta.version"))
         (branch      (git-config "meta.branch"))
         (licence     (or (git-config "meta.licence") "bsd-2-clause")))
    (unless type
      (error "meta.type not set — run: git config meta.type <c99-binary|c99-header|lisp-actor|shell-bats|quadlet-stack>"))
    (unless application
      (error "meta.application not set — run: git config meta.application <name>"))
    (unless role
      (error "meta.role not set — run: git config meta.role <role>"))
    (unless version
      (error "meta.version not set — run: git config meta.version <semver>"))
    (unless branch
      (error "meta.branch not set — run: git config meta.branch <main|master|develop>"))
    (list :type type
          :application application
          :role role
          :version version
          :branch branch
          :licence licence)))

;;; ---------------------------------------------------------------------------
;;; Type dispatch
;;; ---------------------------------------------------------------------------

(defparameter *type-scaffold-map*
  '(("c99-binary"     . c99-binary-scaffold)
    ("c99-header"     . c99-header-scaffold)
    ("lisp-actor"     . lisp-actor-scaffold)
    ("shell-bats"     . shell-bats-scaffold)
    ("quadlet-stack"  . quadlet-stack-scaffold))
  "Maps meta.type values to their Consfigurator defproplist symbols.")

(defun scaffold-for-type (meta-type)
  "Return the scaffold property symbol for META-TYPE, or error."
  (let ((entry (assoc meta-type *type-scaffold-map* :test #'string=)))
    (unless entry
      (error "Unknown meta.type: ~S~%Valid types: ~{~A~^, ~}"
             meta-type (mapcar #'car *type-scaffold-map*)))
    (cdr entry)))

;;; ---------------------------------------------------------------------------
;;; Consfigurator application
;;; ---------------------------------------------------------------------------

(defun apply-scaffold (config)
  "Apply the correct Consfigurator property list for CONFIG using :local connection."
  (let ((scaffold-sym (scaffold-for-type (getf config :type))))
    (format t "~&[dps-meta] Applying ~A scaffold for ~A ~A~%"
            (getf config :type)
            (getf config :application)
            (getf config :version))
    ;; Consfigurator :local connection — applies properties to the machine
    ;; Lisp is running on, i.e. the checkout directory.
    (consfigurator:with-deployed-system (:local)
      (funcall scaffold-sym config))))

;;; ---------------------------------------------------------------------------
;;; Attestation: run FiveAM specs against generated output
;;; ---------------------------------------------------------------------------

(defun run-attestation-specs ()
  "Run FiveAM attestation specs.  Return T if all pass, NIL if any fail."
  (format t "~&[dps-meta] Running attestation specs...~%")
  (let ((results (fiveam:run 'dps.meta.attestation:all)))
    (fiveam:explain! results)
    (every #'fiveam:test-passed-p results)))

;;; ---------------------------------------------------------------------------
;;; Entry point
;;; ---------------------------------------------------------------------------

(defun main ()
  "Main entry point — called by Roswell or as compiled binary."
  (handler-case
      (let* ((config (read-meta-config)))
        (format t "~&[dps-meta] ~A v~A (~A)~%"
                (getf config :application)
                (getf config :version)
                (getf config :type))
        (apply-scaffold config)
        (let ((specs-passed (run-attestation-specs)))
          (unless specs-passed
            (format *error-output* "~&[dps-meta] FAIL: attestation specs failed.~%")
            (uiop:quit 1)))
        (format t "~&[dps-meta] Done. All specs passed.~%")
        (uiop:quit 0))
    (error (e)
      (format *error-output* "~&[dps-meta] ERROR: ~A~%" e)
      (uiop:quit 1))))
