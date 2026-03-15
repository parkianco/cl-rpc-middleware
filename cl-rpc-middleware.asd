;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: BSD-3-Clause

;;;; cl-rpc-middleware.asd - JSON-RPC middleware pipeline system
;;;;
;;;; BSD-3-Clause License
;;;; Copyright (c) 2024, Parkian Company LLC

(asdf:defsystem #:cl-rpc-middleware
  :description "JSON-RPC middleware pipeline for request/response transformation"
  :author "Parkian Company LLC"
  :license "Apache-2.0"
  :version "0.1.0"
  :serial t
  :depends-on ()
  :components ((:file "package")
               (:module "src"
                :serial t
                :components ((:file "types")))))

(asdf:defsystem #:cl-rpc-middleware/test
  :description "Tests for cl-rpc-middleware"
  :depends-on (#:cl-rpc-middleware)
  :serial t
  :components ((:module "test"
                :components ((:file "test-rpc-middleware"))))
  :perform (asdf:test-op (o c)
             (let ((result (uiop:symbol-call :cl-rpc-middleware.test :run-tests)))
               (unless result
                 (error "Tests failed")))))
