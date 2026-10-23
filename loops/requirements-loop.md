# Requirements Loop

Use with the target repository's `loops/project.md`.
Read `loops/agent-development-loop.md` and `loops/quality-gate.md`; their gate rules
apply throughout this loop.

## Model policy

Before starting, read `loops/model-policy.yaml`. Use its `plan.model` for planning,
`execute.model` for implementation, and `validate.model` for verification. Use only
the declared provider and models; record each phase and model in `.ai/progress.md` or
the completion report. If the policy is missing or invalid, stop and mark the loop
blocked.

1. Classify the request and build an inventory from it and relevant docs.
2. Classify each item as implemented, partial, missing, obsolete, ambiguous, or blocked.
3. Map implemented items to code paths and evidence.
   Include security/access requirements, efficiency budgets, and their owners. Missing
   evidence cannot be classified as verified implementation.
4. Resolve obsolete docs before implementing behavior.
5. For clear missing or partial items, follow the ownership boundary in `loops/project.md`.
6. Implement one complete requirement at a time.
7. Add positive and important negative-path tests.
8. Update docs named by the project's documentation touchpoints.
9. Run narrow checks after each meaningful batch, then review and ship checks.

Do not invent product behavior from vague roadmap language. Ask only when a reasonable
assumption would be risky.

Evidence: `Requirement | Status | Owner | Code path | Docs path | Positive evidence | Negative evidence | Residual risk`

Stop only when every requirement is implemented, obsolete, explicitly deferred, or
blocked with a concrete reason. Do not silently convert ambiguous requirements into
implementation decisions.
A requirement passes only with applicable gate evidence; unresolved required scope
prevents `Status: complete` under `loops/quality-gate.md`.
