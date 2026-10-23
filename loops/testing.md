# Shared Agent Testing Guidance

Apply `loops/quality-gate.md`. Select required commands from the target project's
`loops/quality-gate.json` and scope/risk rules from `loops/project.md`.

Every behavior change needs evidence appropriate to its risk:

- positive evidence for the expected path;
- negative, empty, denied, invalid, or failure evidence when relevant;
- deterministic tests for regressions when practical;
- a documented reason for every skipped check.

For asynchronous work, also verify cancellation, timeout behavior, retry limits,
duplicate execution, idempotency, cleanup, and concurrency. Passing a build or typecheck
does not prove behavioral correctness.

For sensitive access paths, verify authorized success and denial for anonymous,
unauthorized, expired/revoked, wrong-owner, and cross-tenant identities where relevant.
Test API enforcement directly; frontend hiding is not authorization evidence.

For performance changes, capture a representative baseline and after-change
measurement against documented budgets. For repository audits, run all owned
language/service suites and report coverage gaps rather than claiming all code passed.

Required skips, unavailable environments, and flaky failures block the corresponding
gate. Add regression tests for meaningful behavior and threat cases; avoid tests that
only copy implementation details or check wording. Do not weaken assertions, scan
rules, or budgets to get a passing result. Evidence must match the final code snapshot.
