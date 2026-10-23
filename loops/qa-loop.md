# QA Loop

Use with the target repository's `loops/project.md`.
Read `loops/agent-development-loop.md` and `loops/quality-gate.md`; their gate rules
apply throughout this loop.

## Model policy

Before starting, read `loops/model-policy.yaml`. Use its `plan.model` for planning,
`execute.model` for implementation, and `validate.model` for verification. Use only
the declared provider and models; record each phase and model in `.ai/progress.md` or
the completion report. If the policy is missing or invalid, stop and mark the loop
blocked.

1. Classify the change and identify the primary user workflow affected by it.
2. Map it to routes, components, APIs, jobs, scripts, and docs.
3. Exercise the normal path and relevant empty, invalid, denied, loading, boundary,
   and failure states.
4. For UI, check responsive layout, readability, contrast, focus, and status communication.
   Verify API authorization independently of frontend controls, including wrong-owner,
   cross-tenant, expired-session, and anonymous requests where applicable. Exercise
   bounded payloads, retries, and representative load against project budgets.
5. Record each issue with reproduction, expected result, actual result, and severity.
6. Fix only in-scope issues and rerun affected checks.

For each requirement, report the tested path, positive result, negative result when
relevant, commands run, untested states, and residual risk.

Stop when the primary workflow and relevant failure states have evidence and all
applicable gates in `loops/quality-gate.md` pass. Mark the loop
`blocked` when the workflow cannot be exercised because of a missing service, credential,
environment, or external dependency; record the exact missing prerequisite. Do not mark
QA complete based only on static inspection when runtime verification was required.
