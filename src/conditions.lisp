;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(in-package #:cl-rpc-middleware)

(define-condition cl-rpc-middleware-error (error)
  ((message :initarg :message :reader cl-rpc-middleware-error-message))
  (:report (lambda (condition stream)
             (format stream "cl-rpc-middleware error: ~A" (cl-rpc-middleware-error-message condition)))))
