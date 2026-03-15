;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(in-package #:cl-rpc-middleware)

;;; Core types for cl-rpc-middleware
(deftype cl-rpc-middleware-id () '(unsigned-byte 64))
(deftype cl-rpc-middleware-status () '(member :ready :active :error :shutdown))
