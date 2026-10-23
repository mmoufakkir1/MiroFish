# Enhance Loop

Use with the target repository's `loops/project.md`.
Read `loops/agent-development-loop.md` and `loops/quality-gate.md`; their gate rules
apply throughout this loop.

## Model policy

Before starting, read `loops/model-policy.yaml`. Use its `plan.model` for planning,
`execute.model` for implementation, and `validate.model` for verification. Use only
the declared provider and models; record each phase and model in `.ai/progress.md` or
the completion report. If the policy is missing or invalid, stop and mark the loop
blocked.

## Plan

1. Classify the enhancement and bound the scope; preserve unrelated working-tree changes.
2. Inspect callers, tests, docs, nearby patterns, and the current diff.
   If intended behavior or relevant data flow remains materially unclear, use
   `investigation-loop.md` before selecting an implementation.
3. Write or update `.ai/plan.md` with the objective, acceptance criteria, unchanged
   behavior, affected paths, validation matrix, risks, and the stop condition.
4. Rank findings by correctness, security, duplication, error handling, maintainability,
   performance, and accessibility.
   Define access/abuse cases and establish a representative baseline before changing
   a hot path, cache, query, concurrency limit, or performance budget.

## Execute

5. Pick one safe, high-value improvement and state behavior that must remain unchanged.
6. Implement the smallest maintainable change and remove obsolete code it replaces.
7. Add positive and negative tests when behavior could regress. Update `.ai/progress.md`
   after each logical unit.

## Validate

8. Run the narrowest useful check, then broader checks required by project risk and
   `loops/project.md`.
9. Review the diff and record changed files, evidence, skipped checks, and residual risk.
10. Apply `loops/quality-gate.md` before marking `complete`, `blocked`, or `deferred`.
    Include security review and measured efficiency evidence where required.
    Repeat only when a failed gate or
    unmet acceptance criterion identifies another in-scope unit; never iterate on
    speculative or stylistic cleanup.

Prefer existing patterns over new wrappers, dependencies, or abstractions. Stop when
remaining work is speculative or stylistic-only, even if another possible improvement
can be found.

If the next change requires a product, architecture, migration, security, or ownership
decision that is not documented, mark the loop `blocked` or `deferred` instead of
guessing.
