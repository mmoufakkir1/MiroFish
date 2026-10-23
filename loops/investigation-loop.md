# Investigation Loop

Use this loop when behavior, ownership, data flow, or the cause of a failure is unclear
enough that implementation would depend on an unverified assumption. Use with the
target repository's `loops/project.md`. Read `loops/agent-development-loop.md`,
`loops/quality-gate.md`, and `loops/evidence.md`; their rules apply throughout.

## Model policy

Read `loops/model-policy.yaml` before starting. Use its declared provider and
`plan.model`, `execute.model`, and `validate.model` for the corresponding phases;
record each in `.ai/progress.md` or the completion report. If the policy is missing or
invalid, stop and mark the loop blocked.

## Plan

1. State the question, why it matters, the target and relevant boundaries, and the
   decision the evidence will support. Classify the task and preserve unrelated
   working-tree changes.
2. Read project scope, ownership, access rules, budgets, quality gate, and relevant
   docs. Inspect the current diff and trace relevant paths, callers, and data flow
   before choosing probes.
3. Write or update `.ai/plan.md` with the question, acceptance criteria, in-scope and
   out-of-scope paths, permitted probes, expected evidence, validation matrix, risks,
   and stop condition. Do not run probes that change external state unless project
   scope permits them.

## Investigate

4. Record findings in `.ai/progress.md` or a task-local evidence file using the format
   in `loops/evidence.md`. Label each claim as an observation, inference, or unknown;
   attach its source and a command or reproduction where applicable.
5. Choose the next probe to resolve the highest-impact unknown. Prefer read-only,
   narrowly scoped probes first. Bound command time, result size, retries, and runtime
   interaction according to project policy.
6. Keep raw logs, traces, and generated artifacts in an appropriate task-local path.
   Summarize the relevant portion and link to the artifact; do not paste unbounded
   output into `.ai/` state or the final report. Redact credentials and sensitive data.
7. Verify important conclusions with an independent source or second method where
   practical. Record contradictory evidence, failed probes, tool/version details, and
   remaining unknowns. Never present an inference as a verified fact.

## Decide and validate

8. Compare findings with acceptance criteria. If evidence is insufficient, run another
   bounded probe or mark the task blocked/deferred with the specific missing evidence
   or decision. Do not fill gaps with plausible-sounding assumptions.
9. If evidence supports a change, hand off verified findings and unresolved risks to
   exactly one suitable implementation loop (usually fix, enhance, or requirements).
   Keep investigation and implementation scope aligned; exploration alone is not
   implementation completion.
10. Validate conclusions and any resulting change against the project gate on the final
    snapshot. Report the question, evidence references, conclusion, remaining unknowns,
    files changed, commands and results, skipped checks, and residual risk. Apply
    `loops/quality-gate.md` before marking the task complete.

Stop when the question is answered to the acceptance criteria, the next probe is
speculative or outside permitted scope, or an external dependency prevents progress.
Record the stop reason and next useful action.
