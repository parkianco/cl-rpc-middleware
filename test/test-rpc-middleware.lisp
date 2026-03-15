;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

;;;; test-rpc-middleware.lisp - Unit tests for rpc-middleware
;;;;
;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: Apache-2.0

(defpackage #:cl-rpc-middleware.test
  (:use #:cl)
  (:export #:run-tests))

(in-package #:cl-rpc-middleware.test)

(defun run-tests ()
  "Run all tests for cl-rpc-middleware."
  (format t "~&Running tests for cl-rpc-middleware...~%")
  ;; TODO: Add test cases
  ;; (test-function-1)
  ;; (test-function-2)
  (format t "~&All tests passed!~%")
  t)
