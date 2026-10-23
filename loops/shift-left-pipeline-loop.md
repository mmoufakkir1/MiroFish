# Shift-Left Pipeline Loop

Use with the target repository's `loops/project.md` to design or improve when quality
and security checks run. Keep required commands in `loops/quality-gate.json` and
project-specific thresholds in `loops/project.md`; this template defines placement
and decision criteria.
Read `loops/agent-development-loop.md` and `loops/quality-gate.md`; their gate rules
apply throughout this loop.

## Model policy

Before starting, read `loops/model-policy.yaml`. Use its `plan.model` for planning,
`execute.model` for implementation, and `validate.model` for verification. Use only
the declared provider and models; record each phase and model in `.ai/progress.md` or
the completion report. If the policy is missing or invalid, stop and mark the loop
blocked.

## Plan

1. Map the current path from editing and commit through pull request, merge, release,
   deployment, and production feedback.
2. Inspect existing commands, CI workflows, hooks, scanner configuration, artifact
   handling, owners, and known flaky or noisy checks. Preserve unrelated changes.
3. For each relevant risk, identify the earliest useful check and its expected runtime,
   owner, failure signal, and whether it should block progress.
4. Record a stage-by-stage validation matrix in `.ai/plan.md`; do not invent commands or
   make an unreliable check a merge blocker.
5. For sensitive operations, map identity to permitted action, resource, and
   ownership/tenant scope. Record where the backend enforces each decision and which
   unauthorized cases must be denied.

## Execute

6. Put quick formatting, lint, type, focused unit, and secret checks at the developer
   stage when the repository supports them. Keep local hooks fast and easy to run.
7. Put authoritative, repeatable build and test checks plus relevant secret, dependency,
   static-analysis, and infrastructure scans on pull requests. Publish clear findings;
   require a blocker only when it is actionable, reliable, and has an owner.
8. Put slower integration/end-to-end, artifact/container checks, SBOM generation, and
   release policy checks after merge or before release, as appropriate.
9. Promote the same immutable artifact that passed verification. Add deployment smoke
   and health checks, and identify production signals that should create follow-up work.
10. Keep required commands in `loops/quality-gate.json` and ownership in
    `loops/project.md`. Document accepted gaps, false-positive handling, and skipped
    checks with concrete reasons.

## Validate

11. Verify the new or changed checks using the narrowest available path, including
    expected failure behavior and that findings identify an actionable owner or fix.
12. Confirm CI is authoritative even when local hooks can be bypassed; confirm blocking
    checks are stable and scoped to relevant changes where practical.
13. Review secrets handling, dependency coverage, artifact identity, permissions, and
    deployment feedback. Do not treat passing lint, build, or scanners alone as proof
    of behavioral correctness.
14. For access-control changes, require evidence for authorized access and rejection of
    anonymous, unauthorized, wrong-owner, and cross-tenant requests. Confirm the
    frontend grants no authority and reveals no protected data after denial.
15. Exercise a failing required check to confirm local/CI gates refuse completion,
    and verify gate results become stale after source/config changes. Include pipeline
    permissions, untrusted PR isolation, and required efficiency checks.
16. Report stages changed, checks and results, skipped gates with reasons, ownership,
    and residual risk using the standard completion format.

Stop when the requested pipeline change has evidence at each affected stage and
`loops/quality-gate.md` passes. Mark the loop `blocked` for missing authority or an
unresolved external dependency, and
`deferred` for explicitly out-of-scope stages.
