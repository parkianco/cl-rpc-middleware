;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: BSD-3-Clause

;;;; cl-rpc-middleware.asd - JSON-RPC middleware pipeline system
;;;;
;;;; BSD-3-Clause License
;;;; Copyright (c) 2024, Parkian Company LLC

(asdf:defsystem #:cl-rpc-middleware
  :name "cl-rpc-middleware"
  :description "JSON-RPC middleware pipeline for request/response transformation"
  :author "Park Ian Co"
  :license "Apache-2.0"
  :version "0.1.0"
  :serial t
  :depends-on ()
  :components ((:module "src"
                :serial t
                :components ((:file "package")
                             (:file "conditions")
                             (:file "types")
                             (:file "core"))))
  :in-order-to ((asdf:test-op (asdf:test-op #:cl-rpc-middleware/test))))

(asdf:defsystem #:cl-rpc-middleware/test
  :description "Tests for cl-rpc-middleware"
  :depends-on (#:cl-rpc-middleware)
  :serial t
  :components ((:module "test"
                :serial t
                :components ((:file "test")
                             (:file "test-rpc-middleware"))))
  :perform (asdf:test-op (op c)
             (declare (ignore op c))
             (unless (uiop:symbol-call :cl-rpc-middleware.test :run-tests)
               (error "Tests failed"))))
