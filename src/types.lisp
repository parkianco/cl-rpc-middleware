;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: Apache-2.0

;;;; types.lisp - Core Type Definitions for CL-RPC-MIDDLEWARE
;;;;
;;;; Purpose: Core type definitions for the middleware system.
;;;;
;;;; This module defines the fundamental types used throughout the middleware system
;;;; including middleware protocol, context, result, chain, and registry structures.
;;;; All types are designed for thread-safety and composability.
;;;;
;;;; Standards: Common Lisp Object System (CLOS), JSON-RPC 2.0
;;;; Thread Safety: Yes (immutable core structures, lock-protected mutable state)
;;;; Performance: O(1) for all type operations
;;;; Dependencies: SBCL (uses sb-thread for thread safety)

(in-package #:cl-rpc-middleware)

;;; ============================================================================
;;; Constants and Parameters
;;; ============================================================================

(defparameter *default-middleware-priority* 100
  "Default priority for middleware ordering. Lower values execute first.")

(defparameter *max-middleware-chain-depth* 50
  "Maximum depth of middleware chain to prevent infinite loops.")

(defparameter *middleware-timeout-default* 30
  "Default timeout for middleware execution in seconds.")

(defparameter *context-pool-size* 100
  "Size of context object pool for reduced allocation.")

;;; ============================================================================
;;; Middleware Status Constants
;;; ============================================================================

(defconstant +status-continue+ :continue
  "Middleware completed successfully, continue to next middleware.")

(defconstant +status-short-circuit+ :short-circuit
  "Middleware requests short-circuit, skip remaining middleware and return.")

(defconstant +status-abort+ :abort
  "Middleware requests abort, stop processing and return error.")

(defconstant +status-error+ :error
  "Middleware encountered an error.")

(defconstant +status-skip+ :skip
  "Middleware was skipped (disabled or condition not met).")

;;; ============================================================================
;;; Thread Safety Utilities
;;; ============================================================================

(defun make-lock (&optional name)
  "Create a new mutex lock."
  (sb-thread:make-mutex :name (or name "lock")))

(defmacro with-lock ((lock) &body body)
  "Execute BODY with LOCK held."
  `(sb-thread:with-mutex (,lock)
     ,@body))

;;; ============================================================================
;;; Middleware Protocol (Abstract Base)
;;; ============================================================================

(defstruct (middleware (:constructor nil)
                       (:copier nil))
  "Abstract base structure for all middleware implementations.

   This defines the protocol that all middleware must implement.
   Concrete middleware types should include this as a base.

   NAME: Unique identifier for this middleware instance
   VERSION: Semantic version string (e.g., \"1.0.0\")
   PRIORITY: Execution order priority (lower = earlier)
   ENABLED: Whether this middleware is currently active
   CONFIG: Configuration parameters as property list
   DESCRIPTION: Human-readable description of middleware purpose
   DEPENDENCIES: List of middleware names this depends on
   TAGS: Keywords for categorization and filtering
   CREATED-AT: Unix timestamp when middleware was created
   LOCK: Mutex for thread-safe state modifications"
  (name "unnamed" :type string :read-only t)
  (version "1.0.0" :type string :read-only t)
  (priority *default-middleware-priority* :type fixnum)
  (enabled t :type boolean)
  (config nil :type list)
  (description "" :type string)
  (dependencies nil :type list)
  (tags nil :type list)
  (created-at (get-universal-time) :type integer :read-only t)
  (lock (sb-thread:make-mutex :name "middleware-lock") :type t))

(defgeneric middleware-process (middleware context)
  (:documentation
   "Process a request through this middleware.

   This is the main entry point for middleware execution.
   Implementations should:
   1. Optionally modify the context
   2. Return a middleware-result
   3. Handle errors gracefully

   MIDDLEWARE: The middleware instance to execute
   CONTEXT: The current middleware-context

   Returns: middleware-result with status and optional response"))

(defgeneric middleware-before (middleware context)
  (:documentation
   "Pre-processing hook called before main processing.

   MIDDLEWARE: The middleware instance
   CONTEXT: The current middleware-context

   Returns: Modified context or signals error"))

(defgeneric middleware-after (middleware context response)
  (:documentation
   "Post-processing hook called after main processing.

   MIDDLEWARE: The middleware instance
   CONTEXT: The current middleware-context
   RESPONSE: The response from processing

   Returns: Modified response"))

(defgeneric middleware-error (middleware context error)
  (:documentation
   "Error handling hook called when an error occurs.

   MIDDLEWARE: The middleware instance
   CONTEXT: The current middleware-context
   ERROR: The condition that was signaled

   Returns: Error response or re-signals"))

(defgeneric middleware-cleanup (middleware context)
  (:documentation
   "Cleanup hook called after all processing completes.

   Always called, even if an error occurred.
   Used for releasing resources, closing connections, etc.

   MIDDLEWARE: The middleware instance
   CONTEXT: The current middleware-context

   Returns: Nothing"))

(defgeneric middleware-health-check (middleware)
  (:documentation
   "Check if middleware is healthy and operational.

   MIDDLEWARE: The middleware instance

   Returns: T if healthy, NIL and error message otherwise"))

(defgeneric middleware-stats (middleware)
  (:documentation
   "Get statistics about middleware execution.

   MIDDLEWARE: The middleware instance

   Returns: Association list of statistics"))

;;; Default method implementations
(defmethod middleware-before ((mw middleware) context)
  "Default before hook does nothing."
  (declare (ignore mw))
  context)

(defmethod middleware-after ((mw middleware) context response)
  "Default after hook returns response unchanged."
  (declare (ignore mw context))
  response)

(defmethod middleware-error ((mw middleware) context error)
  "Default error hook re-signals the error."
  (declare (ignore mw context))
  (error error))

(defmethod middleware-cleanup ((mw middleware) context)
  "Default cleanup hook does nothing."
  (declare (ignore mw context))
  nil)

(defmethod middleware-health-check ((mw middleware))
  "Default health check returns healthy."
  (declare (ignore mw))
  t)

(defmethod middleware-stats ((mw middleware))
  "Default stats returns empty list."
  `((:name . ,(middleware-name mw))
    (:enabled . ,(middleware-enabled mw))
    (:priority . ,(middleware-priority mw))))

;;; ============================================================================
;;; Middleware Context
;;; ============================================================================

(defstruct (middleware-context (:conc-name context-))
  "Context object passed through the middleware chain.

   Carries request data, response data, and metadata through all middleware.
   Context is mutable - middleware can modify it as it passes through.

   REQUEST: Original RPC request (parsed JSON as alist)
   RESPONSE: Response being built (nil until set)
   METADATA: Arbitrary key-value metadata
   START-TIME: High-resolution start timestamp
   CLIENT-IP: Client IP address string
   METHOD: RPC method name
   PARAMS: RPC method parameters
   ID: RPC request ID
   HEADERS: HTTP headers as hash table
   USER: Authenticated user identifier
   ROLES: User roles list
   SESSION: Session object if authenticated
   ABORT-P: Whether chain should abort
   ERROR: Error condition if any
   TRACE-ID: Distributed tracing ID
   SPAN-ID: Current span ID
   PARENT-SPAN-ID: Parent span ID
   DEPTH: Current chain depth
   PATH: Middleware names traversed
   LOCK: Mutex for thread-safe modifications"
  (request nil :type (or null list))
  (response nil :type t)
  (metadata (make-hash-table :test 'equal) :type hash-table)
  (start-time (get-internal-real-time) :type integer)
  (client-ip "0.0.0.0" :type string)
  (method "" :type string)
  (params nil :type t)
  (id nil :type t)
  (headers (make-hash-table :test 'equalp) :type hash-table)
  (user nil :type t)
  (roles nil :type list)
  (session nil :type t)
  (abort-p nil :type boolean)
  (error nil :type t)
  (trace-id nil :type (or null string))
  (span-id nil :type (or null string))
  (parent-span-id nil :type (or null string))
  (depth 0 :type fixnum)
  (path nil :type list)
  (lock (sb-thread:make-mutex :name "context-lock") :type t))

(defun context-get (context key &optional default)
  "Get a metadata value from the context.

   CONTEXT: The middleware context
   KEY: String or keyword key
   DEFAULT: Value to return if key not found

   Returns: The stored value or DEFAULT"
  (declare (type middleware-context context))
  (gethash key (context-metadata context) default))

(defun context-set (context key value)
  "Set a metadata value in the context.

   Thread-safe: Uses context lock.

   CONTEXT: The middleware context
   KEY: String or keyword key
   VALUE: Value to store

   Returns: VALUE"
  (declare (type middleware-context context))
  (sb-thread:with-mutex ((context-lock context))
    (setf (gethash key (context-metadata context)) value)))

(defun context-delete (context key)
  "Delete a metadata value from the context.

   Thread-safe: Uses context lock.

   CONTEXT: The middleware context
   KEY: String or keyword key

   Returns: T if key existed, NIL otherwise"
  (declare (type middleware-context context))
  (sb-thread:with-mutex ((context-lock context))
    (remhash key (context-metadata context))))

(defun context-has-key-p (context key)
  "Check if context has a metadata key.

   CONTEXT: The middleware context
   KEY: String or keyword key

   Returns: T if key exists, NIL otherwise"
  (declare (type middleware-context context))
  (nth-value 1 (gethash key (context-metadata context))))

(defun context-elapsed-ms (context)
  "Get elapsed time since context creation in milliseconds.

   CONTEXT: The middleware context

   Returns: Elapsed time as float in milliseconds"
  (declare (type middleware-context context))
  (let ((now (get-internal-real-time)))
    (* (/ (- now (context-start-time context))
          internal-time-units-per-second)
       1000.0)))

(defun context-add-path (context middleware-name)
  "Add middleware name to the traversal path.

   Thread-safe: Uses context lock.

   CONTEXT: The middleware context
   MIDDLEWARE-NAME: Name of middleware being entered

   Returns: Updated path"
  (declare (type middleware-context context)
           (type string middleware-name))
  (sb-thread:with-mutex ((context-lock context))
    (push middleware-name (context-path context))))

(defun context-increment-depth (context)
  "Increment the chain depth counter.

   Thread-safe: Uses context lock.

   CONTEXT: The middleware context

   Returns: New depth value
   Signals: ERROR if max depth exceeded"
  (declare (type middleware-context context))
  (sb-thread:with-mutex ((context-lock context))
    (incf (context-depth context))
    (when (> (context-depth context) *max-middleware-chain-depth*)
      (error "Maximum middleware chain depth (~D) exceeded"
             *max-middleware-chain-depth*))
    (context-depth context)))

(defun context-decrement-depth (context)
  "Decrement the chain depth counter.

   Thread-safe: Uses context lock.

   CONTEXT: The middleware context

   Returns: New depth value"
  (declare (type middleware-context context))
  (sb-thread:with-mutex ((context-lock context))
    (decf (context-depth context))
    (context-depth context)))

(defun copy-context (context)
  "Create a shallow copy of the context.

   Useful for branching execution or creating child contexts.
   Note: Metadata hash table is shared (not deep copied).

   CONTEXT: The middleware context to copy

   Returns: New middleware-context"
  (declare (type middleware-context context))
  (make-middleware-context
   :request (context-request context)
   :response (context-response context)
   :metadata (context-metadata context)
   :start-time (context-start-time context)
   :client-ip (context-client-ip context)
   :method (context-method context)
   :params (context-params context)
   :id (context-id context)
   :headers (context-headers context)
   :user (context-user context)
   :roles (context-roles context)
   :session (context-session context)
   :abort-p (context-abort-p context)
   :error (context-error context)
   :trace-id (context-trace-id context)
   :span-id (context-span-id context)
   :parent-span-id (context-parent-span-id context)
   :depth (context-depth context)
   :path (copy-list (context-path context))))

;;; ============================================================================
;;; Middleware Result
;;; ============================================================================

(defstruct (middleware-result (:conc-name result-))
  "Result of middleware processing.

   Encapsulates the outcome of a single middleware execution.

   STATUS: Processing status (:continue, :short-circuit, :abort, :error, :skip)
   RESPONSE: Response data if any
   CONTINUE-P: Whether to continue processing
   METADATA: Additional result metadata
   ERROR: Error condition if STATUS is :error
   DURATION-MS: Processing time in milliseconds
   MIDDLEWARE-NAME: Name of middleware that produced this result"
  (status +status-continue+ :type keyword)
  (response nil :type t)
  (metadata nil :type list)
  (error nil :type t)
  (duration-ms 0.0 :type float)
  (middleware-name "" :type string))

(defun result-continue-p (result)
  "Check if result indicates chain should continue.

   RESULT: The middleware result

   Returns: T if processing should continue"
  (declare (type middleware-result result))
  (eq (result-status result) +status-continue+))

(defun result-short-circuit-p (result)
  "Check if result requests short-circuit.

   RESULT: The middleware result

   Returns: T if chain should short-circuit"
  (declare (type middleware-result result))
  (eq (result-status result) +status-short-circuit+))

(defun result-abort-p (result)
  "Check if result requests abort.

   RESULT: The middleware result

   Returns: T if chain should abort"
  (declare (type middleware-result result))
  (eq (result-status result) +status-abort+))

(defun result-error-p (result)
  "Check if result indicates an error.

   RESULT: The middleware result

   Returns: T if an error occurred"
  (declare (type middleware-result result))
  (eq (result-status result) +status-error+))

(defun result-skip-p (result)
  "Check if result indicates middleware was skipped.

   RESULT: The middleware result

   Returns: T if middleware was skipped"
  (declare (type middleware-result result))
  (eq (result-status result) +status-skip+))

(defun make-continue-result (&optional response)
  "Create a result indicating processing should continue.

   RESPONSE: Optional response data

   Returns: middleware-result with :continue status"
  (make-middleware-result
   :status +status-continue+
   :response response))

(defun make-short-circuit-result (response)
  "Create a result indicating short-circuit with response.

   RESPONSE: The response to return immediately

   Returns: middleware-result with :short-circuit status"
  (make-middleware-result
   :status +status-short-circuit+
   :response response))

(defun make-abort-result (error-message)
  "Create a result indicating chain abort.

   ERROR-MESSAGE: Description of why abort occurred

   Returns: middleware-result with :abort status"
  (make-middleware-result
   :status +status-abort+
   :error error-message))

(defun make-error-result (error &optional message)
  "Create a result indicating an error occurred.

   ERROR: The error condition
   MESSAGE: Optional error message

   Returns: middleware-result with :error status"
  (make-middleware-result
   :status +status-error+
   :error error
   :metadata (when message (list :message message))))

(defun make-skip-result (&optional reason)
  "Create a result indicating middleware was skipped.

   REASON: Optional reason for skipping

   Returns: middleware-result with :skip status"
  (make-middleware-result
   :status +status-skip+
   :metadata (when reason (list :reason reason))))

;;; ============================================================================
;;; Middleware Chain
;;; ============================================================================

(defstruct (middleware-chain (:conc-name chain-))
  "Ordered collection of middleware for request processing.

   Manages a sequence of middleware that process requests in order.
   Supports dynamic modification (add/remove/reorder) at runtime.

   NAME: Name of this chain for identification
   MIDDLEWARES: Ordered list of middleware instances
   CONFIG: Chain-level configuration
   ENABLED: Whether the chain is active
   DEFAULT-TIMEOUT: Default timeout for middleware execution
   ERROR-HANDLER: Function called on unhandled errors
   BEFORE-HOOKS: Functions called before chain execution
   AFTER-HOOKS: Functions called after chain execution
   STATS: Execution statistics
   LOCK: Mutex for thread-safe modifications"
  (name "default-chain" :type string)
  (middlewares nil :type list)
  (config nil :type list)
  (enabled t :type boolean)
  (default-timeout *middleware-timeout-default* :type integer)
  (error-handler nil :type (or null function))
  (before-hooks nil :type list)
  (after-hooks nil :type list)
  (stats (make-chain-stats) :type chain-stats)
  (lock (sb-thread:make-mutex :name "chain-lock") :type t))

(defstruct (chain-stats (:conc-name stats-))
  "Statistics for middleware chain execution.

   TOTAL-REQUESTS: Total requests processed
   SUCCESSFUL-REQUESTS: Requests completed successfully
   FAILED-REQUESTS: Requests that failed
   SHORT-CIRCUITED: Requests that short-circuited
   ABORTED: Requests that were aborted
   TOTAL-TIME-MS: Total processing time
   AVG-TIME-MS: Average processing time
   MAX-TIME-MS: Maximum processing time
   MIN-TIME-MS: Minimum processing time
   LAST-ERROR: Last error that occurred
   LAST-ERROR-TIME: When last error occurred"
  (total-requests 0 :type integer)
  (successful-requests 0 :type integer)
  (failed-requests 0 :type integer)
  (short-circuited 0 :type integer)
  (aborted 0 :type integer)
  (total-time-ms 0.0 :type float)
  (avg-time-ms 0.0 :type float)
  (max-time-ms 0.0 :type float)
  (min-time-ms most-positive-single-float :type float)
  (last-error nil :type t)
  (last-error-time 0 :type integer))

(defun chain-add (chain middleware &optional position)
  "Add middleware to the chain.

   Thread-safe: Uses chain lock.
   If POSITION is specified, inserts at that position (0-indexed).
   Otherwise, inserts in priority order.

   CHAIN: The middleware chain
   MIDDLEWARE: The middleware to add
   POSITION: Optional position for insertion

   Returns: Updated middleware list"
  (declare (type middleware-chain chain)
           (type middleware middleware))
  (sb-thread:with-mutex ((chain-lock chain))
    (let ((middlewares (chain-middlewares chain)))
      (cond
        ;; Insert at specific position
        (position
         (setf (chain-middlewares chain)
               (append (subseq middlewares 0 (min position (length middlewares)))
                       (list middleware)
                       (when (< position (length middlewares))
                         (subseq middlewares position)))))
        ;; Insert in priority order
        (t
         (setf (chain-middlewares chain)
               (merge 'list
                      (list middleware)
                      (copy-list middlewares)
                      #'<
                      :key #'middleware-priority))))
      (chain-middlewares chain))))

(defun chain-remove (chain middleware-name)
  "Remove middleware from the chain by name.

   Thread-safe: Uses chain lock.

   CHAIN: The middleware chain
   MIDDLEWARE-NAME: Name of middleware to remove

   Returns: Removed middleware or NIL if not found"
  (declare (type middleware-chain chain)
           (type string middleware-name))
  (sb-thread:with-mutex ((chain-lock chain))
    (let ((found nil))
      (setf (chain-middlewares chain)
            (remove-if (lambda (mw)
                         (when (string= (middleware-name mw) middleware-name)
                           (setf found mw)
                           t))
                       (chain-middlewares chain)))
      found)))

(defun chain-find (chain middleware-name)
  "Find middleware in the chain by name.

   CHAIN: The middleware chain
   MIDDLEWARE-NAME: Name of middleware to find

   Returns: The middleware or NIL if not found"
  (declare (type middleware-chain chain)
           (type string middleware-name))
  (find middleware-name (chain-middlewares chain)
        :key #'middleware-name
        :test #'string=))

(defun chain-insert-before (chain target-name middleware)
  "Insert middleware before another in the chain.

   Thread-safe: Uses chain lock.

   CHAIN: The middleware chain
   TARGET-NAME: Name of middleware to insert before
   MIDDLEWARE: The middleware to insert

   Returns: T if inserted, NIL if target not found"
  (declare (type middleware-chain chain)
           (type string target-name)
           (type middleware middleware))
  (sb-thread:with-mutex ((chain-lock chain))
    (let ((pos (position target-name (chain-middlewares chain)
                         :key #'middleware-name
                         :test #'string=)))
      (when pos
        (setf (chain-middlewares chain)
              (append (subseq (chain-middlewares chain) 0 pos)
                      (list middleware)
                      (subseq (chain-middlewares chain) pos)))
        t))))

(defun chain-insert-after (chain target-name middleware)
  "Insert middleware after another in the chain.

   Thread-safe: Uses chain lock.

   CHAIN: The middleware chain
   TARGET-NAME: Name of middleware to insert after
   MIDDLEWARE: The middleware to insert

   Returns: T if inserted, NIL if target not found"
  (declare (type middleware-chain chain)
           (type string target-name)
           (type middleware middleware))
  (sb-thread:with-mutex ((chain-lock chain))
    (let ((pos (position target-name (chain-middlewares chain)
                         :key #'middleware-name
                         :test #'string=)))
      (when pos
        (setf (chain-middlewares chain)
              (append (subseq (chain-middlewares chain) 0 (1+ pos))
                      (list middleware)
                      (when (< (1+ pos) (length (chain-middlewares chain)))
                        (subseq (chain-middlewares chain) (1+ pos)))))
        t))))

(defun chain-enable (chain middleware-name)
  "Enable a middleware in the chain.

   Thread-safe: Uses individual middleware lock.

   CHAIN: The middleware chain
   MIDDLEWARE-NAME: Name of middleware to enable

   Returns: T if found and enabled, NIL if not found"
  (declare (type middleware-chain chain)
           (type string middleware-name))
  (let ((mw (chain-find chain middleware-name)))
    (when mw
      (sb-thread:with-mutex ((middleware-lock mw))
        (setf (middleware-enabled mw) t))
      t)))

(defun chain-disable (chain middleware-name)
  "Disable a middleware in the chain.

   Thread-safe: Uses individual middleware lock.

   CHAIN: The middleware chain
   MIDDLEWARE-NAME: Name of middleware to disable

   Returns: T if found and disabled, NIL if not found"
  (declare (type middleware-chain chain)
           (type string middleware-name))
  (let ((mw (chain-find chain middleware-name)))
    (when mw
      (sb-thread:with-mutex ((middleware-lock mw))
        (setf (middleware-enabled mw) nil))
      t)))

(defun chain-reorder (chain new-order)
  "Reorder middleware in the chain.

   Thread-safe: Uses chain lock.

   CHAIN: The middleware chain
   NEW-ORDER: List of middleware names in desired order

   Returns: T if successful, NIL if any middleware not found"
  (declare (type middleware-chain chain)
           (type list new-order))
  (sb-thread:with-mutex ((chain-lock chain))
    (let ((ordered nil)
          (found-all t))
      (dolist (name new-order)
        (let ((mw (find name (chain-middlewares chain)
                        :key #'middleware-name
                        :test #'string=)))
          (if mw
              (push mw ordered)
              (setf found-all nil))))
      (when found-all
        (setf (chain-middlewares chain) (nreverse ordered)))
      found-all)))

(defun chain-clear (chain)
  "Remove all middleware from the chain.

   Thread-safe: Uses chain lock.

   CHAIN: The middleware chain

   Returns: Number of middleware removed"
  (declare (type middleware-chain chain))
  (sb-thread:with-mutex ((chain-lock chain))
    (let ((count (length (chain-middlewares chain))))
      (setf (chain-middlewares chain) nil)
      count)))

(defun chain-length (chain)
  "Get the number of middleware in the chain.

   CHAIN: The middleware chain

   Returns: Number of middleware"
  (declare (type middleware-chain chain))
  (length (chain-middlewares chain)))

(defun chain-middleware-names (chain)
  "Get list of middleware names in the chain.

   CHAIN: The middleware chain

   Returns: List of middleware name strings"
  (declare (type middleware-chain chain))
  (mapcar #'middleware-name (chain-middlewares chain)))

;;; ============================================================================
;;; Middleware Configuration
;;; ============================================================================

(defstruct (middleware-config (:conc-name config-))
  "Configuration container for middleware.

   Provides a type-safe way to store and access configuration parameters.

   VALUES: Hash table of configuration values
   SCHEMA: Optional schema for validation
   DEFAULTS: Default values hash table
   READONLY-P: Whether config is immutable
   LOCK: Mutex for thread-safe access"
  (values (make-hash-table :test 'equal) :type hash-table)
  (schema nil :type t)
  (defaults (make-hash-table :test 'equal) :type hash-table)
  (readonly-p nil :type boolean)
  (lock (sb-thread:make-mutex :name "config-lock") :type t))

(defun make-config (&rest pairs)
  "Create a new configuration with initial key-value pairs.

   PAIRS: Alternating keys and values

   Returns: New middleware-config

   Example: (make-config :timeout 30 :enabled t)"
  (let ((config (make-middleware-config)))
    (loop for (key value) on pairs by #'cddr
          do (setf (gethash key (config-values config)) value))
    config))

(defun config-get (config key &optional default)
  "Get a configuration value.

   CONFIG: The middleware configuration
   KEY: Configuration key
   DEFAULT: Value to return if key not found

   Returns: The configuration value or DEFAULT"
  (declare (type middleware-config config))
  (multiple-value-bind (value found)
      (gethash key (config-values config))
    (if found
        value
        (or (gethash key (config-defaults config))
            default))))

(defun config-set (config key value)
  "Set a configuration value.

   Thread-safe: Uses config lock.
   Signals error if config is readonly.

   CONFIG: The middleware configuration
   KEY: Configuration key
   VALUE: Value to set

   Returns: VALUE"
  (declare (type middleware-config config))
  (when (config-readonly-p config)
    (error "Cannot modify readonly configuration"))
  (sb-thread:with-mutex ((config-lock config))
    (setf (gethash key (config-values config)) value)))

(defun config-merge (config other)
  "Merge another configuration into this one.

   Thread-safe: Uses config lock.
   Values from OTHER override values in CONFIG.

   CONFIG: The target configuration
   OTHER: The source configuration

   Returns: CONFIG"
  (declare (type middleware-config config)
           (type middleware-config other))
  (when (config-readonly-p config)
    (error "Cannot modify readonly configuration"))
  (sb-thread:with-mutex ((config-lock config))
    (maphash (lambda (k v)
               (setf (gethash k (config-values config)) v))
             (config-values other)))
  config)

(defun config-to-plist (config)
  "Convert configuration to property list.

   CONFIG: The middleware configuration

   Returns: Property list of key-value pairs"
  (declare (type middleware-config config))
  (let ((plist nil))
    (maphash (lambda (k v)
               (push v plist)
               (push k plist))
             (config-values config))
    plist))

(defun config-from-plist (plist)
  "Create configuration from property list.

   PLIST: Property list of key-value pairs

   Returns: New middleware-config"
  (apply #'make-config plist))

(defun config-freeze (config)
  "Make configuration readonly.

   Thread-safe: Uses config lock.

   CONFIG: The middleware configuration

   Returns: CONFIG"
  (declare (type middleware-config config))
  (sb-thread:with-mutex ((config-lock config))
    (setf (config-readonly-p config) t))
  config)

(defun config-clone (config)
  "Create a mutable copy of configuration.

   CONFIG: The middleware configuration to clone

   Returns: New middleware-config with same values"
  (declare (type middleware-config config))
  (let ((new-config (make-middleware-config)))
    (maphash (lambda (k v)
               (setf (gethash k (config-values new-config)) v))
             (config-values config))
    (maphash (lambda (k v)
               (setf (gethash k (config-defaults new-config)) v))
             (config-defaults config))
    new-config))

;;; ============================================================================
;;; Middleware Registry
;;; ============================================================================

(defvar *middleware-registry* (make-hash-table :test 'equal)
  "Global registry of middleware types.
   Maps middleware type names to constructor functions.")

(defvar *middleware-registry-lock* (sb-thread:make-mutex :name "middleware-registry-lock")
  "Lock for thread-safe registry access.")

(defun register-middleware-type (name constructor &optional documentation)
  "Register a middleware type in the global registry.

   Thread-safe: Uses registry lock.

   NAME: String name for the middleware type
   CONSTRUCTOR: Function that creates middleware instances
   DOCUMENTATION: Optional description of the middleware type

   Returns: NAME"
  (declare (type string name)
           (type function constructor))
  (sb-thread:with-mutex (*middleware-registry-lock*)
    (setf (gethash name *middleware-registry*)
          (list :constructor constructor
                :documentation (or documentation "")
                :registered-at (get-universal-time))))
  name)

(defun unregister-middleware-type (name)
  "Remove a middleware type from the registry.

   Thread-safe: Uses registry lock.

   NAME: String name of the middleware type

   Returns: T if found and removed, NIL otherwise"
  (declare (type string name))
  (sb-thread:with-mutex (*middleware-registry-lock*)
    (remhash name *middleware-registry*)))

(defun find-middleware-type (name)
  "Find a middleware type in the registry.

   NAME: String name of the middleware type

   Returns: Registry entry or NIL if not found"
  (declare (type string name))
  (gethash name *middleware-registry*))

(defun list-middleware-types ()
  "List all registered middleware types.

   Returns: List of (name . documentation) pairs"
  (let ((types nil))
    (sb-thread:with-mutex (*middleware-registry-lock*)
      (maphash (lambda (name entry)
                 (push (cons name (getf entry :documentation))
                       types))
               *middleware-registry*))
    (sort types #'string< :key #'car)))

(defun make-middleware-instance (type-name &rest config)
  "Create a middleware instance from a registered type.

   TYPE-NAME: String name of the middleware type
   CONFIG: Configuration parameters to pass to constructor

   Returns: New middleware instance
   Signals: ERROR if type not found"
  (declare (type string type-name))
  (let ((entry (find-middleware-type type-name)))
    (unless entry
      (error "Middleware type ~S not found in registry" type-name))
    (apply (getf entry :constructor) config)))

(defun describe-middleware (type-name)
  "Get detailed description of a middleware type.

   TYPE-NAME: String name of the middleware type

   Returns: Description as a string or NIL if not found"
  (declare (type string type-name))
  (let ((entry (find-middleware-type type-name)))
    (when entry
      (getf entry :documentation))))

;;; ============================================================================
;;; Utility Functions
;;; ============================================================================

(defun current-timestamp ()
  "Get current Unix timestamp.

   Returns: Integer Unix timestamp"
  (- (get-universal-time) 2208988800)) ; Convert to Unix epoch

(defun timestamp-to-string (timestamp)
  "Convert Unix timestamp to ISO 8601 string.

   TIMESTAMP: Unix timestamp integer

   Returns: ISO 8601 formatted string"
  (multiple-value-bind (sec min hour day month year)
      (decode-universal-time (+ timestamp 2208988800))
    (format nil "~4,'0D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0DZ"
            year month day hour min sec)))

(defun generate-trace-id ()
  "Generate a unique trace ID for distributed tracing.

   Returns: 32-character hex string"
  (format nil "~(~32,'0X~)"
          (random (expt 2 128))))

(defun generate-span-id ()
  "Generate a unique span ID for distributed tracing.

   Returns: 16-character hex string"
  (format nil "~(~16,'0X~)"
          (random (expt 2 64))))

;;; ============================================================================
;;; Debug Support
;;; ============================================================================

(defvar *debug-middleware* nil
  "When T, enables verbose debug logging for middleware.")

(defun debug-log (format-string &rest args)
  "Log a debug message if debug mode is enabled.

   FORMAT-STRING: Format string for message
   ARGS: Format arguments

   Returns: NIL"
  (when *debug-middleware*
    (apply #'format t (concatenate 'string "[MIDDLEWARE DEBUG] " format-string "~%")
           args))
  nil)

(defun dump-context (context &optional (stream t))
  "Dump context contents for debugging.

   CONTEXT: The middleware context
   STREAM: Output stream (default T for stdout)

   Returns: NIL"
  (declare (type middleware-context context))
  (format stream "~%=== Middleware Context Dump ===~%")
  (format stream "Method: ~A~%" (context-method context))
  (format stream "Client IP: ~A~%" (context-client-ip context))
  (format stream "User: ~A~%" (context-user context))
  (format stream "Roles: ~A~%" (context-roles context))
  (format stream "Trace ID: ~A~%" (context-trace-id context))
  (format stream "Depth: ~D~%" (context-depth context))
  (format stream "Path: ~A~%" (context-path context))
  (format stream "Elapsed: ~,2Fms~%" (context-elapsed-ms context))
  (format stream "Abort: ~A~%" (context-abort-p context))
  (format stream "Error: ~A~%" (context-error context))
  (format stream "Metadata:~%")
  (maphash (lambda (k v)
             (format stream "  ~A: ~A~%" k v))
           (context-metadata context))
  (format stream "=== End Context Dump ===~%")
  nil)
