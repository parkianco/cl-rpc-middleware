;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(in-package #:cl-rpc-middleware)

(defconstant +status-continue+ :continue)
(defconstant +status-short-circuit+ :short-circuit)
(defconstant +status-abort+ :abort)
(defconstant +status-error+ :error)

(defstruct middleware-context
  (id 0)
  (metadata nil))

(defstruct middleware-chain
  (id 0)
  (metadata nil))

(defstruct middleware-result
  (id 0)
  (metadata nil))

(defun %ensure-plist (metadata)
  (cond ((null metadata) nil)
        ((listp metadata) metadata)
        (t (list :value metadata))))

(defun %plist-put (plist &rest pairs)
  (let ((result (copy-list (%ensure-plist plist))))
    (loop for (key value) on pairs by #'cddr
          do (setf (getf result key) value))
    result))

(defun %plist-delete (plist key)
  (loop for (entry-key entry-value) on (%ensure-plist plist) by #'cddr
        unless (eql entry-key key)
          append (list entry-key entry-value)))

(defun context-metadata (context)
  "Return the metadata plist for CONTEXT."
  (middleware-context-metadata context))

(defun context-get (context key &optional default)
  "Read KEY from CONTEXT metadata."
  (getf (%ensure-plist (middleware-context-metadata context)) key default))

(defun context-set (context key value)
  "Store KEY and VALUE in CONTEXT metadata."
  (setf (middleware-context-metadata context)
        (%plist-put (middleware-context-metadata context) key value))
  context)

(defun context-delete (context key)
  "Remove KEY from CONTEXT metadata."
  (setf (middleware-context-metadata context)
        (%plist-delete (middleware-context-metadata context) key))
  context)

(defun context-has-key-p (context key)
  "Return true when CONTEXT contains KEY."
  (let ((sentinel (gensym "MISSING")))
    (not (eq sentinel (context-get context key sentinel)))))

(defun chain-middlewares (chain)
  "Return the middleware list associated with CHAIN."
  (or (getf (%ensure-plist (middleware-chain-metadata chain)) :middlewares) nil))

(defun chain-name (chain)
  "Return the configured name for CHAIN."
  (getf (%ensure-plist (middleware-chain-metadata chain)) :name "default"))

(defun chain-add (chain middleware)
  "Append MIDDLEWARE to CHAIN."
  (setf (middleware-chain-metadata chain)
        (%plist-put (middleware-chain-metadata chain)
                    :middlewares (append (chain-middlewares chain)
                                         (list middleware))))
  chain)

(defun chain-remove (chain middleware)
  "Remove MIDDLEWARE from CHAIN."
  (setf (middleware-chain-metadata chain)
        (%plist-put (middleware-chain-metadata chain)
                    :middlewares (remove middleware
                                         (chain-middlewares chain)
                                         :test #'equal)))
  chain)

(defun chain-clear (chain)
  "Remove all middleware from CHAIN."
  (setf (middleware-chain-metadata chain)
        (%plist-put (middleware-chain-metadata chain) :middlewares nil))
  chain)

(defun result-status (result)
  "Return RESULT status."
  (getf (%ensure-plist (middleware-result-metadata result)) :status))

(defun result-metadata (result)
  "Return RESULT metadata."
  (middleware-result-metadata result))

(defun result-response (result)
  "Return RESULT response payload."
  (getf (%ensure-plist (middleware-result-metadata result)) :response))

(defun result-continue-p (result)
  "Return true when RESULT indicates continuation."
  (eq (result-status result) +status-continue+))

(defun result-abort-p (result)
  "Return true when RESULT indicates abortion."
  (eq (result-status result) +status-abort+))

(defun result-error-p (result)
  "Return true when RESULT indicates an error."
  (eq (result-status result) +status-error+))

(defun continue-chain (&optional response)
  "Create a continuation result."
  (make-middleware-result
   :metadata (list :status +status-continue+ :response response)))

(defun short-circuit (&optional response)
  "Create a short-circuit result."
  (make-middleware-result
   :metadata (list :status +status-short-circuit+ :response response)))

(defun abort-chain (&optional response)
  "Create an abort result."
  (make-middleware-result
   :metadata (list :status +status-abort+ :response response)))

(defun execute-middleware (middleware context)
  "Run MIDDLEWARE against CONTEXT."
  (cond ((functionp middleware) (funcall middleware context))
        ((and (symbolp middleware) (fboundp middleware))
         (funcall middleware context))
        (t
         (error 'cl-rpc-middleware-error
                :message (format nil "Unsupported middleware ~S" middleware)))))

(defun run-chain (chain context)
  "Run CHAIN against CONTEXT and return a middleware result."
  (loop with current = context
        for middleware in (chain-middlewares chain)
        for step = (execute-middleware middleware current)
        do (cond ((typep step 'middleware-result)
                  (return step))
                 ((typep step 'middleware-context)
                  (setf current step))
                 (t
                  (error 'cl-rpc-middleware-error
                         :message (format nil
                                          "Middleware ~S returned ~S"
                                          middleware
                                          step))))
        finally (return (continue-chain current))))
