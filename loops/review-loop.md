# Review Loop

Use with the target repository's `loops/project.md`.
Read `loops/agent-development-loop.md` and `loops/quality-gate.md`; their gate rules
apply throughout this loop.

## Model policy

Before starting, read `loops/model-policy.yaml`. Use its `plan.model` for planning,
`execute.model` for any requested fixes, and `validate.model` for review verification.
Use only the declared provider and models; record each phase and model in `.ai/progress.md`
or the completion report. If the policy is missing or invalid, stop and mark the loop
blocked.

1. Classify the change, read the intended behavior, and inspect the current diff.
2. Also inspect the surrounding repository and relevant legacy code; review scope is not
   limited to staged, changed, or pushable files. Use `quality-audit-loop.md` for a full
   repository baseline when requested.
3. Inspect relevant files, callers, tests, docs, and project patterns.
4. Trace inputs, outputs, nulls, bounds, async flow, retries, cleanup, permissions,
   logging, performance, and security.
5. Check success and meaningful failure-path coverage.
6. For UI, inspect actual route/state, CSS tokens, contrast, focus, and responsive behavior.
7. Report Critical, High, Medium, or Low findings with impact and a concrete recommendation.
8. Map changed areas to validation evidence and list skipped checks as risk.

For security, use `loops/agents/security.md` and explicitly check server-side access control
for each sensitive resource/action, including object ownership and tenant boundaries.
Verify unauthenticated, unauthorized, and cross-tenant requests fail closed. Treat
frontend guards and hidden controls as UX only; check XSS, unsafe URLs, CSRF/session
handling, browser storage, and exposure of secrets or sensitive data. Also check input
validation, SQL or command injection, SSRF, unsafe file access, sensitive logs, and
dependency changes.
For loops, polling, watchers, retries, and background jobs, check cancellation,
timeouts, retry limits, duplicate execution, idempotency, cleanup, and concurrency.

Passing lint, typecheck, or build is not by itself proof of behavioral correctness.
Use `loops/agents/performance.md` to evaluate bounded work, query/I/O cost, caching,
frontend payloads, and required measurements against the baseline/budget.

A read-only review ends with findings and an explicit gate result. Approve code only
when `loops/quality-gate.md` passes, required evidence is current, and no Critical/High
findings remain. Report Medium/Low findings with ownership and disposition.
