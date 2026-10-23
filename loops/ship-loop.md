# Ship Loop

Use with the target repository's `loops/project.md`.
Read `loops/agent-development-loop.md` and `loops/quality-gate.md`; their gate rules
apply throughout this loop.

## Model policy

Before starting, read `loops/model-policy.yaml`. Use its `plan.model` for planning,
`execute.model` for release preparation, and `validate.model` for final verification.
Use only the declared provider and models; record each phase and model in `.ai/progress.md`
or the completion report. If the policy is missing or invalid, stop and mark the loop
blocked.

1. Classify the change, check status, and review the diff for unrelated changes.
2. Run the repository quality baseline when the task requests an audit or when legacy
   health is unknown; do not treat diff-only checks as proof that old code is healthy.
3. Run QA for affected user workflows.
4. Run every applicable command in the project's validation matrix, including its
   touched-file pre-commit gate when defined.
5. Fix blocking failures with `fix-loop.md`.
6. Review the final diff and confirm no Critical or High findings remain.
7. Map every changed requirement to implementation and validation evidence.
8. Run the project's post-change command after code changes.
   Verify the final snapshot and configured gate result after the last edit. Confirm
   security/access review, performance budgets, artifact identity, and rollback evidence
   for relevant release paths. Require CI checks before merge when configured.
9. Report changed files, requirements, commands and results, skipped checks, legacy findings, and residual risk.

Do not claim ship readiness when a required project-defined gate is unverified.

Ship is complete only when `loops/quality-gate.md` passes on the final snapshot and
the standard report has `Status: complete`. A skipped required check prevents ship
readiness; documenting a reason does not waive it. Use `Status: blocked` for external failures or
missing authority; use `Status: deferred` for intentionally postponed work.
