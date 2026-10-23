# Language Standards Baseline

Apply the standards for every language present in the repository, including unchanged legacy code when it is in the audit scope. Prefer the repository's configured formatter, linter, compiler, test runner, and security tooling over introducing new dependencies.

## All languages

- Keep behavior explicit, deterministic, testable, and minimally coupled.
- Validate external input at boundaries; handle null, empty, malformed, oversized, unauthorized, timeout, and partial-failure cases.
- Never commit secrets, tokens, private keys, generated credentials, or sensitive data in logs.
- Use structured errors and actionable messages; preserve causes and avoid swallowing exceptions.
- Avoid dead code, duplicated business rules, uncontrolled retries, unbounded loops, race-prone shared state, and unnecessary allocations.
- Keep public interfaces documented, backwards-compatible where required, and covered by positive and negative tests.
- Prefer small focused modules, clear names, narrow ownership, and existing project patterns.

## TypeScript and JavaScript

- Use strict TypeScript; avoid `any`, unsafe assertions, implicit coercion, mutation of shared state, and floating promises.
- Use the configured ESLint and formatter. Keep React hooks dependency-correct and components accessible with semantic HTML, keyboard support, labels, and visible focus.
- Validate API and form data at boundaries with the project's schema validator; handle loading, empty, error, unauthorized, and retry states.
- Treat async work as cancellable where applicable; avoid stale updates, duplicate submissions, and unbounded client-side work.
- Keep secrets server-side and use framework server/client boundaries correctly.

## Python

- Follow PEP 8 and the repository's formatter/linter/type checker; add type hints to public functions and non-trivial data structures.
- Avoid broad exception handling, mutable default arguments, hidden global state, shell-string execution, unsafe deserialization, and blocking work in async code.
- Use context managers for files, sockets, subprocesses, and database resources; make retries bounded and idempotent.
- Validate external data and preserve exception context. Add tests for malformed input, empty results, timeouts, and provider failures.

## Vue

- Use the configured Vue/TypeScript rules, keep templates semantic and accessible, and avoid mutating props or duplicating state derived from props.
- Keep side effects in lifecycle/composable boundaries with cleanup; handle loading, empty, error, and stale-request states.

## SQL

- Use parameterized queries and least-privilege access. Define constraints, indexes, transaction boundaries, and safe migration direction explicitly.
- Review nullability, duplicate rows, pagination, locking, N+1 queries, destructive statements, and rollback behavior.

## HTML, CSS, and Tailwind

- Use semantic landmarks, accessible names, keyboard-operable controls, responsive layouts, sufficient contrast, and visible focus.
- Reuse project tokens and spacing scales; avoid unexplained magic values, layout overflow, invalid nesting, and content hidden only by color.

## PowerShell and shell scripts

- Quote paths and arguments safely, validate targets before destructive operations, use strict/error-stop behavior where appropriate, and return non-zero exit codes on failure.
- Avoid command injection, broad recursive deletion, leaked secrets, unbounded polling, and assumptions about the current directory.

## Go

- Run `gofmt`, `go vet`, and the repository's tests. Check returned errors, context cancellation, goroutine ownership, bounded concurrency, resource cleanup, and data races.
- Avoid unchecked type assertions, package-global mutable state, leaked goroutines, and unbounded channels or retries.
