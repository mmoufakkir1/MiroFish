# Quality Audit Loop

Use with the target repository's `loops/project.md`. This loop audits the repository's existing code, not only the current diff, staged files, or files intended for push.
Read `loops/agent-development-loop.md` and `loops/quality-gate.md`; their gate rules
apply throughout this loop.

## Model policy

Before starting, read `loops/model-policy.yaml`. Use its `plan.model` for planning,
`execute.model` for remediation, and `validate.model` for verification. Use only the
declared provider and models; record each phase and model in `.ai/progress.md` or the
completion report. If the policy is missing or invalid, stop and mark the loop blocked.

1. Inventory the repository's languages, frameworks, package manifests, generated/vendor directories, test suites, and configured quality tools. Read `loops/project.md` before choosing commands.
   Include every owned frontend, backend, API, database, job, script, AI integration,
   and infrastructure area. Record exclusions, review sampling, and uncovered paths.
2. Establish the baseline by running the applicable whole-repository formatter checks, linters, type checks, tests, dependency/security checks, and build checks. Separate pre-existing failures from regressions.
3. Review existing code against `language-standards.md`, project conventions, and the validation matrix. Prioritize correctness, security, data loss, reliability, accessibility, performance, maintainability, and duplicated logic over stylistic cleanup.
4. Inspect code outside the diff, including old modules, dead paths, error handling, boundary cases, secrets, dependencies, database access, background jobs, and user-facing failure states.
   Apply `loops/agents/security.md` and `loops/agents/performance.md` to those areas.
   Trace access decisions across user/service/tenant boundaries and measure relevant
   hot paths with representative data; include configured performance budgets.
5. Record each finding with file, line or symbol, severity, evidence, impact, and the smallest safe remediation. Do not hide legacy failures just because they are unrelated to the current change.
6. Fix only findings within the requested scope or clearly safe high-value defects. Add regression tests for behavior changes and preserve unrelated working-tree changes.
7. Re-run the same whole-repository checks and compare results with the baseline. Confirm that no new failures were introduced and that fixed findings have positive and negative evidence.
8. Report remaining legacy findings separately from regressions, with skipped checks and residual risk.
   Run the executable gate with `-Scope repository` when configured and apply
   `loops/quality-gate.md`. Existing required failures, missing checks, and Critical/High
   findings block repository readiness even when they predate the task.

Do not declare the repository healthy merely because the current diff is clean. A clean diff and a clean repository are separate claims.
