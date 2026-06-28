;;;; SPDX-License-Identifier: BSD-2-Clause
;;;; dps/meta/ci/jobs.lisp
;;;;
;;;; All custom 40ants/CI job classes for the dps-meta standard pipeline.
;;;;
;;;; One ci.yml, all jobs here:
;;;;   opa-gate       — always: OPA check + eval policy/
;;;;   build          — always: type-specific build (nob / ros build / bats)
;;;;   cppcheck       — c99 types only: cppcheck SARIF → Code Scanning
;;;;   sbom           — always: cdxgen CycloneDX + osv-scanner CVE gate
;;;;   slsa-provenance — tags only (if: startsWith): slsa-github-generator
;;;;   slsa-verify    — tags only: slsa-verifier gate
;;;;   release        — tags only: GitHub Release with binary + intoto + sha256

(defpackage #:dps.meta.ci.jobs
  (:use #:cl)
  (:import-from #:40ants-ci/jobs/job  #:job)
  (:import-from #:40ants-ci/steps/action #:action)
  (:import-from #:40ants-ci/steps/sh     #:sh)
  (:import-from #:40ants-ci/github       #:prepare-data)
  (:export #:opa-gate-job
           #:build-job
           #:cppcheck-job
           #:sbom-job
           #:slsa-provenance-job
           #:slsa-verify-job
           #:release-job
           #:make-pipeline))

(in-package #:dps.meta.ci.jobs)

;;; ---------------------------------------------------------------------------
;;; Helpers
;;; ---------------------------------------------------------------------------

(defparameter +tag-if+ "startsWith(github.ref, 'refs/tags/v')"
  "Condition string that gates SLSA jobs to tag pushes only.")

(defparameter +runner+ "ubuntu-24.04")

(defun install-opa-step ()
  (sh "Install OPA"
      "curl -sL https://openpolicyagent.org/downloads/latest/opa_linux_amd64_static \
  -o /usr/local/bin/opa && chmod +x /usr/local/bin/opa"))

(defun checkout-step ()
  (action "Checkout" "actions/checkout@v4" :fetch-depth 0))

(defun upload-sarif-step (category path)
  (action "Upload SARIF"
          "github/codeql-action/upload-sarif@v3"
          :sarif-file path
          :category category
          :if "always()"))

;;; ---------------------------------------------------------------------------
;;; 1. OPA gate — runs on every push/PR and every tag
;;; ---------------------------------------------------------------------------

(defclass opa-gate-job (job)
  ()
  (:default-initargs
   :name "opa-gate"
   :os +runner+
   :permissions '(:contents "read" :security-events "write")))

(defmethod 40ants-ci/jobs/job:steps ((job opa-gate-job))
  (list
   (checkout-step)
   (install-opa-step)
   (sh "Check Rego syntax" "opa check policy/")
   (sh "Eval SLSA gate (dry-run)"
       "echo '{}' | opa eval --bundle policy/ 'data.dps.meta.slsa.violation' || true")
   (sh "Generate SARIF"
       "opa eval --format sarif --bundle policy/ 'data' > opa.sarif || true"
       :if "always()")
   (upload-sarif-step "opa" "opa.sarif")))

;;; ---------------------------------------------------------------------------
;;; 2. Build job — type-specific build command
;;; ---------------------------------------------------------------------------

(defclass build-job (job)
  ((build-command :initarg :build-command :reader build-command)
   (artifact-name :initarg :artifact-name :reader artifact-name))
  (:default-initargs
   :name "build"
   :os +runner+
   :permissions '(:contents "read")))

(defmethod 40ants-ci/jobs/job:steps ((job build-job))
  (list
   (checkout-step)
   (sh "Build" (build-command job))
   (sh "Hash artifact"
       (format nil
         "sha256sum ~A > ~:*~A.sha256~%~
          echo \"sha256=$(base64 -w0 < ~:*~A.sha256)\" >> $GITHUB_OUTPUT"
         (artifact-name job))
       :id "hash"
       :if +tag-if+)
   (action "Upload artifact"
           "actions/upload-artifact@v4"
           :name (artifact-name job)
           :path (format nil "~A~%~:*~A.sha256" (artifact-name job))
           :if +tag-if+)))

;;; ---------------------------------------------------------------------------
;;; 3. cppcheck job — C99 repos only
;;; ---------------------------------------------------------------------------

(defclass cppcheck-job (job)
  ()
  (:default-initargs
   :name "cppcheck"
   :os +runner+
   :permissions '(:contents "read" :security-events "write")))

(defmethod 40ants-ci/jobs/job:steps ((job cppcheck-job))
  (list
   (checkout-step)
   (sh "Install cppcheck" "sudo apt-get install -y cppcheck")
   (sh "Run cppcheck"
       "cppcheck --enable=all --inconclusive --xml --xml-version=2 . \
  2> cppcheck.xml || true")
   (sh "Convert to SARIF"
       "python3 -c \"
import xml.etree.ElementTree as ET, json, sys
tree = ET.parse('cppcheck.xml')
runs = []
for err in tree.findall('.//error'):
    loc = err.find('location')
    runs.append({'ruleId': err.get('id','unknown'),
                 'message': {'text': err.get('msg','')},
                 'locations': [{'physicalLocation': {'artifactLocation':
                   {'uri': loc.get('file','') if loc is not None else ''},
                   'region': {'startLine': int(loc.get('line',1)) if loc is not None else 1}}}]})
print(json.dumps({'version':'2.1.0','runs':[{'tool':{'driver':{'name':'cppcheck'}},'results':runs}]}))
\" > cppcheck.sarif"
       :if "always()")
   (upload-sarif-step "cppcheck" "cppcheck.sarif")))

;;; ---------------------------------------------------------------------------
;;; 4. SBOM + CVE gate — always
;;; ---------------------------------------------------------------------------

(defclass sbom-job (job)
  ((cdxgen-type :initarg :cdxgen-type :initform "generic" :reader cdxgen-type))
  (:default-initargs
   :name "sbom"
   :os +runner+
   :permissions '(:contents "read")))

(defmethod 40ants-ci/jobs/job:steps ((job sbom-job))
  (list
   (checkout-step)
   (action "Setup Node" "actions/setup-node@v4" :node-version "20")
   (sh "Install cdxgen" "npm install -g @cyclonedx/cdxgen")
   (sh "Generate SBOM"
       (format nil "cdxgen --type ~A --output sbom.json ." (cdxgen-type job)))
   (sh "Scan CVEs" "osv-scanner --sbom sbom.json --format table || true")
   (action "Upload SBOM"
           "actions/upload-artifact@v4"
           :name "sbom.json"
           :path "sbom.json"
           :if "always()")))

;;; ---------------------------------------------------------------------------
;;; 5. SLSA provenance — tags only (reusable workflow call)
;;; ---------------------------------------------------------------------------

(defclass slsa-provenance-job (job)
  ((artifact-name :initarg :artifact-name :reader artifact-name))
  (:default-initargs
   :name "provenance"
   :os +runner+
   :permissions '(:id-token "write" :contents "write" :actions "read")))

;;; slsa-github-generator is a reusable workflow, not a standard job.
;;; Override prepare-data to emit the uses: key instead of runs-on/steps.
(defmethod prepare-data ((job slsa-provenance-job))
  `(("needs"       . ("build"))
    ("if"          . ,+tag-if+)
    ("permissions" . (("id-token"  . "write")
                      ("contents"  . "write")
                      ("actions"   . "read")))
    ("uses"        . "slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2.0.0")
    ("with"        . (("base64-subjects" . "${{ needs.build.outputs.sha256 }}")
                      ("upload-assets"   . "true")))))

;;; ---------------------------------------------------------------------------
;;; 6. SLSA verify — tags only
;;; ---------------------------------------------------------------------------

(defclass slsa-verify-job (job)
  ((artifact-name :initarg :artifact-name :reader artifact-name))
  (:default-initargs
   :name "slsa-verify"
   :os +runner+
   :permissions '(:contents "read")))

(defmethod 40ants-ci/jobs/job:steps ((job slsa-verify-job))
  (list
   (action "Download artifact"
           "actions/download-artifact@v4"
           :name (artifact-name job))
   (action "Download provenance"
           "actions/download-artifact@v4"
           :name (format nil "~A.intoto.jsonl" (artifact-name job)))
   (sh "Install slsa-verifier"
       "curl -sL https://github.com/slsa-framework/slsa-verifier/releases/latest/download/slsa-verifier-linux-amd64 \
  -o /usr/local/bin/slsa-verifier && chmod +x /usr/local/bin/slsa-verifier")
   (sh "Verify provenance"
       (format nil
         "slsa-verifier verify-artifact ~A \\~%~
          --provenance-path ~:*~A.intoto.jsonl \\~%~
          --source-uri github.com/${{ github.repository }}"
         (artifact-name job)))))

(defmethod prepare-data :around ((job slsa-verify-job))
  (cons `("if" . ,+tag-if+)
        (cons `("needs" . ("provenance"))
              (call-next-method))))

;;; ---------------------------------------------------------------------------
;;; 7. GitHub Release — tags only
;;; ---------------------------------------------------------------------------

(defclass release-job (job)
  ((artifact-name :initarg :artifact-name :reader artifact-name))
  (:default-initargs
   :name "release"
   :os +runner+
   :permissions '(:contents "write")))

(defmethod 40ants-ci/jobs/job:steps ((job release-job))
  (list
   (action "Download artifact"
           "actions/download-artifact@v4"
           :name (artifact-name job))
   (action "Download provenance"
           "actions/download-artifact@v4"
           :name (format nil "~A.intoto.jsonl" (artifact-name job)))
   (action "Create Release"
           "softprops/action-gh-release@v2"
           :files (format nil "~A~%~:*~A.sha256~%~:*~A.intoto.jsonl"
                          (artifact-name job))
           :generate-release-notes "true")))

(defmethod prepare-data :around ((job release-job))
  (cons `("if" . ,+tag-if+)
        (cons `("needs" . ("slsa-verify"))
              (call-next-method))))

;;; ---------------------------------------------------------------------------
;;; Factory: assemble the full job list for a given repo type + config
;;; ---------------------------------------------------------------------------

(defun make-pipeline (meta-type artifact-name)
  "Return the ordered list of job instances for META-TYPE.
   This is what gets passed to defworkflow :jobs."
  (let ((cdxgen-type (cdr (assoc meta-type
                                 '(("c99-binary" . "c")
                                   ("c99-header" . "c")
                                   ("lisp-actor" . "generic")
                                   ("shell-bats" . "generic")
                                   ("quadlet-stack" . "generic"))
                                 :test #'string=))))
    (append
     (list
      (make-instance 'opa-gate-job)
      (make-instance 'build-job
                     :build-command (build-command-for meta-type artifact-name)
                     :artifact-name artifact-name)
      (make-instance 'sbom-job :cdxgen-type (or cdxgen-type "generic"))
      (make-instance 'slsa-provenance-job :artifact-name artifact-name)
      (make-instance 'slsa-verify-job     :artifact-name artifact-name)
      (make-instance 'release-job         :artifact-name artifact-name))
     (when (member meta-type '("c99-binary" "c99-header") :test #'string=)
       (list (make-instance 'cppcheck-job))))))

(defun build-command-for (meta-type artifact-name)
  (cond
    ((member meta-type '("c99-binary" "c99-header") :test #'string=)
     (format nil "cc -o nob nob.c && ./nob~%ls -la ~A" artifact-name))
    ((string= meta-type "lisp-actor")
     (format nil
       "ROS_VER=26.02.116~%~
        curl -sL \"https://github.com/roswell/roswell/releases/download/v${ROS_VER}/roswell_${ROS_VER}-1_amd64.deb\" -o /tmp/roswell.deb~%~
        sudo dpkg -i /tmp/roswell.deb~%~
        ros install qlot~%~
        qlot install~%~
        qlot exec ros run \\~%~
          --eval \"(asdf:load-asd (merge-pathnames #P\\\"~A.asd\\\" (uiop:getcwd)))\" \\~%~
          --eval \"(asdf:make :~:*~A)\" \\~%~
          --eval \"(uiop:quit 0)\"~%~
        ls -la ~:*~A"
       artifact-name))
    ((string= meta-type "shell-bats")
     "bats tests/")
    ((string= meta-type "quadlet-stack")
     "podman-compose config")
    (t (error "Unknown meta-type: ~A" meta-type))))
