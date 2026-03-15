;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

;;;; test-rpc-middleware.lisp - Unit tests for rpc-middleware
;;;;
;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: Apache-2.0

(in-package #:cl-rpc-middleware.test)

(defun run-tests ()
  "Run the cl-rpc-middleware smoke tests."
  (let ((context (cl-rpc-middleware:make-middleware-context))
        (chain (cl-rpc-middleware:make-middleware-chain)))
    (assert (eq context
                (cl-rpc-middleware:context-set context :request-id 42)))
    (assert (= 42 (cl-rpc-middleware:context-get context :request-id)))
    (assert (cl-rpc-middleware:context-has-key-p context :request-id))

    (cl-rpc-middleware:chain-add
     chain
     (lambda (ctx)
       (cl-rpc-middleware:context-set ctx :seen t)))
    (cl-rpc-middleware:chain-add
     chain
     (lambda (ctx)
       (cl-rpc-middleware:short-circuit
        (cl-rpc-middleware:context-get ctx :seen))))

    (let ((result (cl-rpc-middleware:run-chain chain context)))
      (assert (eq cl-rpc-middleware:+status-short-circuit+
                  (cl-rpc-middleware:result-status result)))
      (assert (eq t (cl-rpc-middleware:result-response result))))

    (cl-rpc-middleware:context-delete context :request-id)
    (assert (not (cl-rpc-middleware:context-has-key-p context :request-id)))
    (assert (eq chain (cl-rpc-middleware:chain-clear chain)))
    t))
