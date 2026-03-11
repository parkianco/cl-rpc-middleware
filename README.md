# cl-rpc-middleware

JSON-RPC middleware pipeline for request/response transformation with **zero external dependencies**.

## Features

- **Middleware pipeline**: Composable request/response handlers
- **Rate limiting**: Per-method rate limits
- **Logging**: Request/response logging
- **Caching**: Response caching with TTL
- **Authentication**: API key and JWT support
- **Pure Common Lisp**: No CFFI, no external libraries

## Installation

```lisp
(asdf:load-system :cl-rpc-middleware)
```

## Quick Start

```lisp
(use-package :cl-rpc-middleware)

;; Create middleware stack
(let ((stack (make-middleware-stack
              (rate-limit-middleware :limit 100)
              (logging-middleware :level :info)
              (cache-middleware :ttl 60)
              (auth-middleware :api-keys '("key1" "key2")))))
  ;; Wrap handler
  (let ((handler (wrap-handler #'my-rpc-handler stack)))
    (funcall handler request)))
```

## API Reference

### Middleware Stack

- `(make-middleware-stack &rest middlewares)` - Create stack
- `(wrap-handler handler stack)` - Wrap handler with middleware

### Built-in Middleware

- `(rate-limit-middleware &key limit window)` - Rate limiting
- `(logging-middleware &key level)` - Request logging
- `(cache-middleware &key ttl)` - Response caching
- `(auth-middleware &key api-keys jwt-secret)` - Authentication
- `(validation-middleware &key schema)` - Request validation

## Testing

```lisp
(asdf:test-system :cl-rpc-middleware)
```

## License

BSD-3-Clause

Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
