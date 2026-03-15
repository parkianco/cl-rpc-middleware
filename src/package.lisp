;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: Apache-2.0

;;;; package.lisp - CL-RPC-MIDDLEWARE Package Definition
;;;;
;;;; Purpose: Package exports for the JSON-RPC middleware library.
;;;;
;;;; This file defines all exported symbols for the cl-rpc-middleware package,
;;;; which provides a modular, composable middleware system for JSON-RPC 2.0 APIs.
;;;; The middleware architecture follows the chain-of-responsibility pattern.
;;;;
;;;; Standards: JSON-RPC 2.0, OWASP API Security Best Practices, RFC 7231/7234/7235
;;;; Thread Safety: Yes (all middleware is thread-safe by design)
;;;; Performance: Optimized for minimal overhead per request
;;;; Dependencies: SBCL (uses sb-thread for thread safety)

(defpackage #:cl-rpc-middleware
  (:use #:cl)
  (:nicknames #:rpc-middleware)
  (:documentation
   "Comprehensive RPC middleware system providing composable cross-cutting concerns.

The middleware architecture enables:
- Modular composition of request/response processing
- Chain-of-responsibility pattern for request handling
- Short-circuit capability for early termination
- Context propagation through the middleware stack
- Async and sync execution modes
- Error isolation and recovery

Key middleware types:
- Authentication (API key, JWT, HMAC, mTLS)
- Rate limiting (token bucket, leaky bucket, sliding window)
- Caching (in-memory, distributed, strategy-based)
- Logging (structured, audit trail, request/response)
- Validation (JSON-RPC, schema, business rules)
- CORS (preflight, headers, origin validation)
- Compression (gzip, deflate, brotli)
- Metrics (Prometheus, OpenTelemetry, custom)
- Error handling (recovery, circuit breaker, fallback)")

  ;; ============================================================================
  ;; Core Types and Protocols
  ;; ============================================================================
  (:export
   #:with-rpc-middleware-timing
   #:rpc-middleware-batch-process
   #:rpc-middleware-health-check;; Middleware Protocol
   #:middleware
   #:middleware-name
   #:middleware-version
   #:middleware-priority
   #:middleware-enabled-p
   #:middleware-config
   #:middleware-process
   #:middleware-before
   #:middleware-after
   #:middleware-error
   #:middleware-cleanup

   ;; Middleware Context
   #:middleware-context
   #:make-middleware-context
   #:context-request
   #:context-response
   #:context-metadata
   #:context-get
   #:context-set
   #:context-delete
   #:context-has-key-p
   #:context-start-time
   #:context-client-ip
   #:context-method
   #:context-params
   #:context-id
   #:context-headers
   #:context-user
   #:context-roles
   #:context-session
   #:context-abort-p
   #:context-error

   ;; Middleware Result
   #:middleware-result
   #:make-middleware-result
   #:result-status
   #:result-response
   #:result-continue-p
   #:result-abort-p
   #:result-error-p
   #:result-metadata

   ;; Result Status Constants
   #:+status-continue+
   #:+status-short-circuit+
   #:+status-abort+
   #:+status-error+

   ;; Middleware Chain
   #:middleware-chain
   #:make-middleware-chain
   #:chain-middlewares
   #:chain-name
   #:chain-config
   #:chain-add
   #:chain-remove
   #:chain-insert-before
   #:chain-insert-after
   #:chain-find
   #:chain-enable
   #:chain-disable
   #:chain-reorder
   #:chain-clear

   ;; Chain Execution
   #:run-chain
   #:run-chain-async
   #:execute-middleware
   #:process-request
   #:process-response
   #:short-circuit
   #:continue-chain
   #:abort-chain

   ;; Middleware Registry
   #:*middleware-registry*
   #:register-middleware-type
   #:unregister-middleware-type
   #:find-middleware-type
   #:list-middleware-types
   #:make-middleware-instance
   #:describe-middleware

   ;; Configuration
   #:middleware-config
   #:make-config
   #:config-get
   #:config-set
   #:config-merge
   #:config-validate
   #:load-config
   #:save-config

   ;; Lifecycle
   #:initialize-middleware
   #:shutdown-middleware
   #:health-check
   #:middleware-stats)

  ;; ============================================================================
  ;; Authentication Middleware
  ;; ============================================================================
  (:export
   #:with-rpc-middleware-timing
   #:rpc-middleware-batch-process
   #:rpc-middleware-health-check;; Core Authentication
   #:auth-middleware
   #:make-auth-middleware
   #:auth-type
   #:auth-realm
   #:auth-required-p
   #:auth-skip-methods
   #:authenticate
   #:verify-credentials
   #:extract-credentials
   #:validate-token

   ;; API Key Authentication
   #:api-key-middleware
   #:make-api-key-middleware
   #:api-key-header
   #:api-key-query-param
   #:api-key-store
   #:validate-api-key
   #:rotate-api-key
   #:revoke-api-key
   #:api-key-info
   #:api-key-rate-limit
   #:api-key-roles

   ;; JWT Authentication
   #:jwt-middleware
   #:make-jwt-middleware
   #:jwt-secret
   #:jwt-algorithm
   #:jwt-issuer
   #:jwt-audience
   #:jwt-expiry
   #:jwt-claims
   #:parse-jwt
   #:validate-jwt
   #:decode-jwt
   #:encode-jwt
   #:refresh-jwt
   #:revoke-jwt
   #:jwt-blacklist

   ;; HMAC Authentication
   #:hmac-middleware
   #:make-hmac-middleware
   #:hmac-algorithm
   #:hmac-header
   #:hmac-timestamp-header
   #:hmac-nonce-header
   #:hmac-secret-store
   #:compute-hmac
   #:verify-hmac
   #:hmac-replay-protection
   #:hmac-timestamp-tolerance

   ;; mTLS Authentication
   #:mtls-middleware
   #:make-mtls-middleware
   #:mtls-ca-cert
   #:mtls-verify-depth
   #:mtls-crl-check
   #:mtls-ocsp-check
   #:verify-client-cert
   #:extract-cert-info
   #:cert-fingerprint

   ;; Session Management
   #:session-middleware
   #:make-session-middleware
   #:session-store
   #:session-timeout
   #:session-cookie-name
   #:session-secure-cookie
   #:session-http-only
   #:session-same-site
   #:create-session
   #:destroy-session
   #:refresh-session
   #:session-get
   #:session-set
   #:session-delete

   ;; Role-Based Access Control
   #:rbac-middleware
   #:make-rbac-middleware
   #:rbac-roles
   #:rbac-permissions
   #:rbac-role-hierarchy
   #:check-permission
   #:has-role-p
   #:get-user-roles
   #:get-role-permissions
   #:add-role
   #:remove-role
   #:assign-permission
   #:revoke-permission)

  ;; ============================================================================
  ;; Rate Limiting Middleware
  ;; ============================================================================
  (:export
   #:with-rpc-middleware-timing
   #:rpc-middleware-batch-process
   #:rpc-middleware-health-check;; Core Rate Limiting
   #:rate-limit-middleware
   #:make-rate-limit-middleware
   #:rate-limit-type
   #:rate-limit-key-extractor
   #:rate-limit-exceeded-handler
   #:rate-limit-headers
   #:check-rate-limit
   #:record-request
   #:get-rate-limit-status
   #:reset-rate-limit
   #:bypass-rate-limit

   ;; Token Bucket Algorithm
   #:token-bucket
   #:make-token-bucket
   #:bucket-capacity
   #:bucket-refill-rate
   #:bucket-refill-interval
   #:bucket-tokens
   #:token-bucket-acquire
   #:token-bucket-try-acquire
   #:token-bucket-refill
   #:token-bucket-reset

   ;; Leaky Bucket Algorithm
   #:leaky-bucket
   #:make-leaky-bucket
   #:leaky-bucket-capacity
   #:leaky-bucket-leak-rate
   #:leaky-bucket-add
   #:leaky-bucket-try-add
   #:leaky-bucket-level
   #:leaky-bucket-empty-p

   ;; Sliding Window Algorithm
   #:sliding-window
   #:make-sliding-window
   #:window-size
   #:window-limit
   #:window-precision
   #:sliding-window-count
   #:sliding-window-add
   #:sliding-window-exceeded-p
   #:sliding-window-reset
   #:sliding-window-cleanup

   ;; Adaptive Rate Limiting
   #:adaptive-rate-limiter
   #:make-adaptive-rate-limiter
   #:adaptive-min-limit
   #:adaptive-max-limit
   #:adaptive-adjustment-factor
   #:adaptive-cooldown-period
   #:adaptive-increase-threshold
   #:adaptive-decrease-threshold
   #:adaptive-adjust
   #:adaptive-get-limit

   ;; Distributed Rate Limiting
   #:distributed-rate-limiter
   #:make-distributed-rate-limiter
   #:distributed-sync-interval
   #:distributed-partition-tolerance
   #:distributed-acquire
   #:distributed-sync

   ;; Rate Limit Key Strategies
   #:rate-limit-key-by-ip
   #:rate-limit-key-by-user
   #:rate-limit-key-by-api-key
   #:rate-limit-key-by-method
   #:rate-limit-key-composite

   ;; Rate Limit Configuration
   #:rate-limit-tier
   #:make-rate-limit-tier
   #:tier-name
   #:tier-limits
   #:tier-priority
   #:get-client-tier
   #:set-client-tier)

  ;; ============================================================================
  ;; Caching Middleware
  ;; ============================================================================
  (:export
   #:with-rpc-middleware-timing
   #:rpc-middleware-batch-process
   #:rpc-middleware-health-check;; Core Caching
   #:cache-middleware
   #:make-cache-middleware
   #:cache-store
   #:cache-key-generator
   #:cache-ttl
   #:cache-max-size
   #:cache-strategy
   #:cache-get
   #:cache-set
   #:cache-delete
   #:cache-clear
   #:cache-exists-p
   #:cache-stats

   ;; Cache Key Generation
   #:cache-key-generator
   #:make-cache-key
   #:cache-key-by-method
   #:cache-key-by-params
   #:cache-key-by-user
   #:cache-key-composite
   #:cache-key-hash

   ;; Cache Strategies
   #:cache-strategy
   #:lru-strategy
   #:lfu-strategy
   #:fifo-strategy
   #:ttl-strategy
   #:adaptive-strategy
   #:strategy-evict
   #:strategy-should-cache-p
   #:strategy-get-priority

   ;; Cache Invalidation
   #:cache-invalidation
   #:make-invalidation-policy
   #:invalidate-by-tag
   #:invalidate-by-pattern
   #:invalidate-by-method
   #:invalidate-by-prefix
   #:invalidate-all
   #:cache-tag
   #:add-cache-tag
   #:get-cache-tags

   ;; Cache Stores
   #:memory-cache-store
   #:make-memory-cache-store
   #:distributed-cache-store
   #:make-distributed-cache-store
   #:tiered-cache-store
   #:make-tiered-cache-store

   ;; Response Caching
   #:cacheable-response-p
   #:cache-control-header
   #:parse-cache-control
   #:generate-etag
   #:check-etag
   #:conditional-get

   ;; Cache Warming
   #:cache-warmer
   #:make-cache-warmer
   #:warm-cache
   #:schedule-warm
   #:warm-priority-methods)

  ;; ============================================================================
  ;; Logging Middleware
  ;; ============================================================================
  (:export
   #:with-rpc-middleware-timing
   #:rpc-middleware-batch-process
   #:rpc-middleware-health-check;; Core Logging
   #:logging-middleware
   #:make-logging-middleware
   #:log-level
   #:log-format
   #:log-destination
   #:log-filter
   #:log-request
   #:log-response
   #:log-error

   ;; Log Levels
   #:+log-trace+
   #:+log-debug+
   #:+log-info+
   #:+log-warn+
   #:+log-error+
   #:+log-fatal+
   #:log-level-name
   #:log-level-value
   #:log-level-enabled-p

   ;; Structured Logging
   #:structured-log
   #:make-structured-log
   #:log-field
   #:log-fields
   #:log-context
   #:log-timestamp
   #:log-correlation-id
   #:log-span-id
   #:log-trace-id
   #:with-log-context
   #:add-log-field

   ;; Log Formatters
   #:log-formatter
   #:json-log-formatter
   #:text-log-formatter
   #:clef-log-formatter
   #:custom-log-formatter
   #:format-log-entry

   ;; Log Destinations
   #:log-destination
   #:console-destination
   #:file-destination
   #:syslog-destination
   #:multi-destination
   #:async-destination
   #:rotating-file-destination

   ;; Log Filtering
   #:log-filter
   #:level-filter
   #:method-filter
   #:ip-filter
   #:rate-filter
   #:sampling-filter
   #:composite-filter

   ;; Audit Logging
   #:audit-middleware
   #:make-audit-middleware
   #:audit-log
   #:audit-event
   #:audit-trail
   #:audit-immutable-store
   #:audit-compliance-report

   ;; Request/Response Logging
   #:request-logger
   #:make-request-logger
   #:log-request-body
   #:log-response-body
   #:log-headers
   #:log-timing
   #:log-sensitive-fields
   #:mask-sensitive-data
   #:sensitive-field-patterns)

  ;; ============================================================================
  ;; Validation Middleware
  ;; ============================================================================
  (:export
   #:with-rpc-middleware-timing
   #:rpc-middleware-batch-process
   #:rpc-middleware-health-check;; Core Validation
   #:validation-middleware
   #:make-validation-middleware
   #:validation-mode
   #:validation-strict-p
   #:validation-error-handler
   #:validate-request
   #:validate-response
   #:validation-result
   #:validation-errors

   ;; JSON-RPC Validation
   #:jsonrpc-validator
   #:make-jsonrpc-validator
   #:validate-jsonrpc-request
   #:validate-jsonrpc-response
   #:validate-jsonrpc-batch
   #:validate-jsonrpc-id
   #:validate-jsonrpc-method
   #:validate-jsonrpc-params

   ;; Schema Validation
   #:schema-validator
   #:make-schema-validator
   #:register-schema
   #:unregister-schema
   #:get-schema
   #:validate-against-schema
   #:schema-error
   #:schema-error-path
   #:schema-error-message

   ;; Type Validation
   #:type-validator
   #:validate-type
   #:validate-string
   #:validate-number
   #:validate-integer
   #:validate-boolean
   #:validate-array
   #:validate-object
   #:validate-null
   #:validate-hex
   #:validate-address
   #:validate-txid
   #:validate-hash

   ;; Constraint Validation
   #:constraint-validator
   #:validate-min
   #:validate-max
   #:validate-min-length
   #:validate-max-length
   #:validate-pattern
   #:validate-enum
   #:validate-format
   #:validate-required
   #:validate-optional
   #:validate-custom

   ;; Parameter Validation
   #:param-validator
   #:make-param-validator
   #:param-spec
   #:validate-params
   #:param-required-p
   #:param-type
   #:param-default
   #:param-constraints
   #:coerce-param

   ;; Business Rule Validation
   #:rule-validator
   #:make-rule-validator
   #:define-validation-rule
   #:apply-rules
   #:rule-priority
   #:rule-condition
   #:rule-action

   ;; Method-Specific Validation
   #:method-validator-registry
   #:register-method-validator
   #:get-method-validator
   #:validate-method-params
   #:method-param-specs)

  ;; ============================================================================
  ;; CORS Middleware
  ;; ============================================================================
  (:export
   #:with-rpc-middleware-timing
   #:rpc-middleware-batch-process
   #:rpc-middleware-health-check;; Core CORS
   #:cors-middleware
   #:make-cors-middleware
   #:cors-config
   #:cors-enabled-p
   #:process-cors-request
   #:handle-preflight
   #:add-cors-headers

   ;; Origin Validation
   #:allowed-origins
   #:allowed-origin-p
   #:origin-pattern
   #:origin-wildcard-p
   #:origin-exact-match-p
   #:origin-regex-match-p
   #:add-allowed-origin
   #:remove-allowed-origin

   ;; Methods and Headers
   #:allowed-methods
   #:allowed-headers
   #:exposed-headers
   #:add-allowed-method
   #:remove-allowed-method
   #:add-allowed-header
   #:remove-allowed-header
   #:add-exposed-header
   #:remove-exposed-header

   ;; Credentials and Caching
   #:allow-credentials-p
   #:preflight-max-age
   #:preflight-cache
   #:cache-preflight-response

   ;; CORS Headers
   #:+access-control-allow-origin+
   #:+access-control-allow-methods+
   #:+access-control-allow-headers+
   #:+access-control-expose-headers+
   #:+access-control-allow-credentials+
   #:+access-control-max-age+
   #:+access-control-request-method+
   #:+access-control-request-headers+
   #:+origin+

   ;; Preflight Handling
   #:preflight-handler
   #:make-preflight-handler
   #:is-preflight-p
   #:generate-preflight-response
   #:validate-preflight-request

   ;; CORS Policies
   #:cors-policy
   #:strict-cors-policy
   #:permissive-cors-policy
   #:custom-cors-policy
   #:apply-cors-policy)

  ;; ============================================================================
  ;; Compression Middleware
  ;; ============================================================================
  (:export
   #:with-rpc-middleware-timing
   #:rpc-middleware-batch-process
   #:rpc-middleware-health-check;; Core Compression
   #:compression-middleware
   #:make-compression-middleware
   #:compression-algorithm
   #:compression-level
   #:compression-threshold
   #:compression-mime-types
   #:compress-response
   #:decompress-request
   #:should-compress-p

   ;; Algorithms
   #:+compression-gzip+
   #:+compression-deflate+
   #:+compression-brotli+
   #:+compression-identity+
   #:algorithm-available-p
   #:algorithm-encode
   #:algorithm-decode

   ;; Gzip Compression
   #:gzip-compress
   #:gzip-decompress
   #:gzip-level
   #:gzip-window-bits
   #:gzip-memory-level

   ;; Deflate Compression
   #:deflate-compress
   #:deflate-decompress
   #:deflate-level
   #:deflate-strategy

   ;; Brotli Compression
   #:brotli-compress
   #:brotli-decompress
   #:brotli-quality
   #:brotli-window-size

   ;; Content Negotiation
   #:accept-encoding-header
   #:parse-accept-encoding
   #:select-encoding
   #:encoding-priority
   #:encoding-quality

   ;; Streaming Compression
   #:compression-stream
   #:make-compression-stream
   #:write-compressed
   #:flush-compression-stream
   #:close-compression-stream

   ;; Compression Statistics
   #:compression-ratio
   #:compression-time
   #:compression-stats
   #:original-size
   #:compressed-size)

  ;; ============================================================================
  ;; Metrics Middleware
  ;; ============================================================================
  (:export
   #:with-rpc-middleware-timing
   #:rpc-middleware-batch-process
   #:rpc-middleware-health-check;; Core Metrics
   #:metrics-middleware
   #:make-metrics-middleware
   #:metrics-registry
   #:metrics-prefix
   #:metrics-labels
   #:record-metric
   #:get-metric
   #:get-all-metrics
   #:reset-metrics

   ;; Metric Types
   #:metric
   #:counter-metric
   #:gauge-metric
   #:histogram-metric
   #:summary-metric
   #:meter-metric

   ;; Counter Operations
   #:counter
   #:make-counter
   #:counter-inc
   #:counter-add
   #:counter-value
   #:counter-reset

   ;; Gauge Operations
   #:gauge
   #:make-gauge
   #:gauge-set
   #:gauge-inc
   #:gauge-dec
   #:gauge-value

   ;; Histogram Operations
   #:histogram
   #:make-histogram
   #:histogram-observe
   #:histogram-buckets
   #:histogram-sum
   #:histogram-count
   #:histogram-percentile

   ;; Summary Operations
   #:summary
   #:make-summary
   #:summary-observe
   #:summary-quantiles
   #:summary-sum
   #:summary-count

   ;; Standard RPC Metrics
   #:rpc-request-count
   #:rpc-request-duration
   #:rpc-request-size
   #:rpc-response-size
   #:rpc-error-count
   #:rpc-active-requests
   #:rpc-method-latency

   ;; Prometheus Export
   #:prometheus-exporter
   #:make-prometheus-exporter
   #:export-prometheus
   #:prometheus-format
   #:prometheus-text-format
   #:prometheus-protobuf-format

   ;; OpenTelemetry Support
   #:otel-exporter
   #:make-otel-exporter
   #:otel-span
   #:otel-trace
   #:otel-meter

   ;; Custom Metrics
   #:define-metric
   #:register-metric
   #:unregister-metric
   #:custom-collector
   #:collect-metrics

   ;; Labels and Dimensions
   #:metric-label
   #:add-label
   #:with-labels
   #:label-cardinality
   #:label-values)

  ;; ============================================================================
  ;; Error Handling Middleware
  ;; ============================================================================
  (:export
   #:with-rpc-middleware-timing
   #:rpc-middleware-batch-process
   #:rpc-middleware-health-check;; Core Error Handling
   #:error-handling-middleware
   #:make-error-handling-middleware
   #:error-handler
   #:error-transformer
   #:error-logger
   #:handle-error
   #:transform-error
   #:recover-from-error

   ;; Error Types
   #:rpc-error
   #:rpc-error-code
   #:rpc-error-message
   #:rpc-error-data
   #:make-rpc-error
   #:parse-error
   #:invalid-request-error
   #:method-not-found-error
   #:invalid-params-error
   #:internal-error
   #:server-error

   ;; Standard JSON-RPC Error Codes
   #:+parse-error-code+
   #:+invalid-request-code+
   #:+method-not-found-code+
   #:+invalid-params-code+
   #:+internal-error-code+
   #:+server-error-min+
   #:+server-error-max+

   ;; Custom Error Codes
   #:+rate-limit-exceeded-code+
   #:+authentication-required-code+
   #:+authorization-failed-code+
   #:+resource-not-found-code+
   #:+resource-conflict-code+
   #:+validation-failed-code+

   ;; Error Recovery
   #:error-recovery
   #:make-error-recovery
   #:recovery-strategy
   #:retry-strategy
   #:fallback-strategy
   #:ignore-strategy
   #:escalate-strategy
   #:can-recover-p
   #:attempt-recovery

   ;; Retry Logic
   #:retry-policy
   #:make-retry-policy
   #:max-retries
   #:retry-delay
   #:retry-backoff
   #:retry-jitter
   #:should-retry-p
   #:execute-with-retry

   ;; Circuit Breaker
   #:circuit-breaker
   #:make-circuit-breaker
   #:circuit-state
   #:circuit-open-p
   #:circuit-closed-p
   #:circuit-half-open-p
   #:circuit-failure-threshold
   #:circuit-success-threshold
   #:circuit-timeout
   #:circuit-execute
   #:circuit-record-success
   #:circuit-record-failure
   #:circuit-reset

   ;; Fallback Handling
   #:fallback-handler
   #:make-fallback-handler
   #:fallback-response
   #:fallback-cache
   #:fallback-default
   #:with-fallback

   ;; Error Response Generation
   #:generate-error-response
   #:sanitize-error
   #:error-to-json
   #:json-to-error
   #:wrap-error

   ;; Error Context
   #:error-context
   #:make-error-context
   #:error-request
   #:error-method
   #:error-params
   #:error-trace
   #:error-timestamp

   ;; Error Notifications
   #:error-notifier
   #:make-error-notifier
   #:notify-error
   #:error-severity
   #:should-notify-p
   #:notification-throttle)

  ;; ============================================================================
  ;; Tracing Middleware
  ;; ============================================================================
  (:export
   #:with-rpc-middleware-timing
   #:rpc-middleware-batch-process
   #:rpc-middleware-health-check;; Core Tracing
   #:tracing-middleware
   #:make-tracing-middleware
   #:trace-enabled-p
   #:trace-sampling-rate
   #:trace-exporter

   ;; Span Operations
   #:span
   #:make-span
   #:span-id
   #:span-trace-id
   #:span-parent-id
   #:span-name
   #:span-start-time
   #:span-end-time
   #:span-status
   #:span-attributes
   #:start-span
   #:end-span
   #:with-span

   ;; Trace Context
   #:trace-context
   #:make-trace-context
   #:extract-trace-context
   #:inject-trace-context
   #:propagate-context)

  ;; ============================================================================
  ;; Utility Exports
  ;; ============================================================================
  (:export
   #:with-rpc-middleware-timing
   #:rpc-middleware-batch-process
   #:rpc-middleware-health-check;; Time Utilities
   #:current-timestamp
   #:timestamp-to-string
   #:string-to-timestamp
   #:duration-to-ms
   #:ms-to-duration

   ;; Hash Utilities
   #:secure-hash
   #:hash-string
   #:hash-bytes
   #:constant-time-compare

   ;; Encoding Utilities
   #:base64-encode
   #:base64-decode
   #:hex-encode
   #:hex-decode
   #:url-encode
   #:url-decode

   ;; JSON Utilities
   #:encode-json
   #:decode-json

   ;; Thread Safety
   #:with-lock
   #:make-lock
   #:atomic-incf
   #:atomic-decf
   #:compare-and-swap

   ;; Debugging
   #:*debug-middleware*
   #:debug-log
   #:trace-middleware
   #:middleware-trace
   #:dump-context))

(in-package #:cl-rpc-middleware)

;;;; ============================================================================
;;;; Version Information
;;;; ============================================================================

(defparameter *middleware-version* "1.0.0"
  "Current version of the middleware package.")
