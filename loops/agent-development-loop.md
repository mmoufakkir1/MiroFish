# Shared Agent Development Workflow

Every task runs through three explicit phases. Do not claim completion until all
three phases have evidence.

## Mandatory quality gate

Read `loops/quality-gate.md` for every task. It defines scope, correctness, security,
efficiency, required evidence, and pass/fail rules for every loop. Use
`quality-audit-loop.md` when asked to validate all existing code. An ordinary change
gate does not certify the whole repository. Missing required evidence blocks completion.

## Shift-left check placement

Choose checks by feedback speed and risk, and run them at the earliest useful point:

1. **While editing or before commit:** use fast formatting, lint, type, focused test,
   and secret checks when the repository provides them. Local hooks improve feedback
   but are not authoritative because they can be skipped.
2. **On pull requests:** require reproducible build, unit tests, secret and dependency
   scans, and applicable static or infrastructure analysis. Show findings on the PR;
   make a check blocking only when it is reliable, actionable, and owned. Fix flaky or
   noisy checks rather than normalizing repeated false alarms.
3. **After merge and before release:** run slower integration/end-to-end and artifact
   checks, generate an SBOM when supported, and validate release policy. Promote the
   same immutable artifact that passed checks instead of rebuilding it for production.
4. **After deployment:** run smoke/health checks and monitor errors, performance, and
   runtime security signals. Turn actionable production findings into regression
   coverage or an earlier pipeline check.

Required commands belong in `loops/quality-gate.json`; project-specific applicability,
required review gates, and owners belong in `loops/project.md`.
Record unavailable or skipped gates with a reason; do not invent commands or treat a
successful build alone as behavioral or security evidence.

For every change that adds or changes a sensitive operation, define the permitted
identity, action, resource, and ownership/tenant scope before implementation. Enforce
that policy server-side at each request. Frontend checks may improve the experience but
must never grant access. Review backend and frontend risks with `loops/agents/security.md` and
include authorized and denied-path evidence.

## Authoritative model policy

`loops/model-policy.yaml` is authoritative for every loop and every phase. Read it
before selecting a loop or model. Use the configured `plan.model`, `execute.model`,
and `validate.model` values exactly; do not rely on hardcoded defaults. If the file is
missing, malformed, or does not declare a required phase, stop and mark the task
blocked. Record the selected provider, phase, and model in `.ai/progress.md` or the
completion report.

## 1. Plan

1. Read `AGENTS.md`, `AGENT_LOOPS.md`, the relevant shared docs, `loops/project.md`,
   `loops/quality-gate.md`, and `loops/model-policy.yaml`. Read `.ai/plan.md` when the
   task is already in progress.
2. Classify the task as docs-only, bug fix, enhancement, refactor, UI, schema/data,
   quality audit, or deployment.
3. Select exactly one primary loop and, when useful, one role prompt from the shared kit.
   Use the model assigned to the phase in `loops/model-policy.yaml`.
   Use `investigation-loop.md` first when a material implementation decision depends on
   unclear behavior, ownership, or failure cause; carry its sourced findings into one
   implementation loop.
4. Inspect the current diff, existing implementation, callers, tests, docs, and nearby
   patterns before choosing an implementation.
5. Create or update `.ai/plan.md` with:
   - objective and explicit out-of-scope work;
   - acceptance criteria and behavior that must remain unchanged;
   - affected paths and ownership boundaries;
   - narrow validation, broader project checks, and any required runtime/visual checks;
   - known risks, dependencies, and stop conditions;
   - fast local feedback, required PR gates, broader release checks, and post-deploy
     evidence relevant to this change;
   - access rules, threat boundaries, and denied/abuse cases for sensitive changes;
   - efficiency risks, representative baseline/budget, and required measurements.
   - evidence sources needed to resolve material unknowns and how results will be kept
     bounded and reproducible.
   Record the actual configured plan model in the metadata or progress log.
6. If a product, architecture, migration, security, or ownership decision is missing,
   stop and mark the task `blocked` or `deferred` with the exact decision required.

## 2. Execute

1. Make the smallest coherent change that satisfies the plan and preserve unrelated
   working-tree changes.
2. Work in one logical unit at a time. After each unit, update `.ai/progress.md` with
   the change, files touched, configured execute model, and the next validation step.
3. Add or update positive and meaningful negative-path coverage when behavior can regress.
   Run the narrowest fast check as soon as the logical unit is ready, then use PR/release
   gates for broader coverage; do not defer all feedback until final validation.
   Enforce access rules, validate external input, and bound work as code is written.
   Reject generated code or dependencies that cannot be explained or verified.
4. Do not start a new iteration merely because one is possible. Continue only when the
   current acceptance criteria are unmet or validation exposes an in-scope defect.

## 3. Validate

1. Run the narrowest useful check for the changed behavior and capture its command,
   exit code, redacted relevant output, snapshot, and the configured validate model.
2. Run required commands from `loops/quality-gate.json` and apply the validation matrix
   in `loops/project.md`, including touched-file gates and
   broader checks required by the selected loop or project risk. Run
   `loops/run-quality-gate.ps1` with the appropriate scope when configured; missing
   required configuration is a blocker, not a passing result.
3. Exercise the affected workflow when runtime verification is required. Include empty,
   invalid, denied, boundary, timeout, retry, cancellation, duplicate-execution, or
   failure states when relevant.
4. Review the final diff for correctness, security, performance, accessibility,
   unnecessary complexity, and unrelated changes.
   Apply `loops/agents/security.md` and `loops/agents/performance.md` to relevant paths.
   Compare efficiency measurements to the baseline/budget. Verify gate evidence is
   current after the last code change; rerun affected checks if it is stale.
5. Update `.ai/progress.md` and `.ai/decisions.md` when applicable. The completion report
   must list changed files, acceptance evidence, commands and results, skipped checks
   with reasons, evidence references and unresolved unknowns, and residual risk.
6. Apply the completion rules in `loops/quality-gate.md`. A skipped required check or
   unresolved Critical/High finding prevents approval; a reason does not waive it.
   Mark the loop `complete`, `blocked`, or `deferred`. Repeat only when a failed gate or
   unmet acceptance criterion gives a concrete reason; otherwise stop.
