# cl-rpc-middleware

`cl-rpc-middleware` is a Common Lisp middleware scaffold for JSON-RPC style
request processing. The full generated API surface is still incomplete, but the
core context and chain helpers below now load and pass smoke tests:

- `context-get`, `context-set`, `context-delete`, `context-has-key-p`
- `chain-add`, `chain-remove`, `chain-clear`, `run-chain`
- `continue-chain`, `short-circuit`, `abort-chain`
- `result-status`, `result-response`

## Installation

```lisp
(asdf:load-system :cl-rpc-middleware)
```

## Example

```lisp
(let ((context (cl-rpc-middleware:make-middleware-context))
      (chain (cl-rpc-middleware:make-middleware-chain)))
  (cl-rpc-middleware:chain-add
   chain
   (lambda (ctx)
     (cl-rpc-middleware:context-set ctx :authenticated t)))
  (cl-rpc-middleware:run-chain chain context))
```

## Testing

```lisp
(asdf:test-system :cl-rpc-middleware)
```

## License

Apache-2.0. See `LICENSE`.
