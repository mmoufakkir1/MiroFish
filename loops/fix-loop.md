# Fix Loop

Use with the target repository's `loops/project.md`.
Read `loops/agent-development-loop.md` and `loops/quality-gate.md`; their gate rules
apply throughout this loop.

## Model policy

Before starting, read `loops/model-policy.yaml`. Use its `plan.model` for planning,
`execute.model` for implementation, and `validate.model` for verification. Use only
the declared provider and models; record each phase and model in `.ai/progress.md` or
the completion report. If the policy is missing or invalid, stop and mark the loop
blocked.

1. Classify the change and preserve unrelated working-tree changes.
2. Reproduce the failure or document the observed behavior.
3. Trace the root cause through the smallest relevant code path.
   If the cause remains unclear, use `investigation-loop.md` and record observations,
   inferences, and unknowns before choosing a fix.
4. State the requirement and expected failure-path behavior.
   Include access boundaries and abuse cases for security fixes; establish a baseline
   and repeatable scenario for performance fixes.
5. Make one focused fix and remove obsolete code it replaces.
6. Add or update positive and negative regression coverage.
7. Run the narrowest check; repeat from step 3 if it fails.
8. Run project-defined broader checks, including any touched-file gate.
9. Record the standard completion report from the shared README.
   Apply `loops/quality-gate.md`; a fixed reproduction alone does not pass required
   regression, security, or efficiency gates.

Do not broaden into unrelated cleanup. Treat failures in touched files as in scope when
the repository's validation rules require them.

Stop and mark the loop `blocked` when the same external failure persists after three
evidence-based attempts, or when the fix requires authority or information unavailable
in the repository. Mark it `deferred` when the issue is understood but intentionally
out of the requested scope.
