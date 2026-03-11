;;;; cl-rpc-middleware.asd - JSON-RPC middleware pipeline system
;;;;
;;;; BSD-3-Clause License
;;;; Copyright (c) 2024, CLPIC Contributors

(asdf:defsystem #:cl-rpc-middleware
  :description "JSON-RPC middleware pipeline for request/response transformation"
  :author "CLPIC Contributors"
  :license "BSD-3-Clause"
  :version "1.0.0"
  :serial t
  :depends-on ()
  :components ((:file "package")
               (:module "src"
                :serial t
                :components ((:file "types")))))
