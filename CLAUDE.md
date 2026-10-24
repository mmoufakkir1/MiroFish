<!-- BEGIN AGENT LOOPS POLICY -->
## Agent Loops policy

This project uses the shared agent-loops workflow. Before acting, read `AGENT_LOOPS.md`,
the selected file in `loops/`, `loops/project.md`, and `loops/model-policy.yaml`.
Read `loops/agent-development-loop.md` and `loops/quality-gate.md` on every task.
Apply correctness, security, and efficiency gates before claiming completion; use
`loops/quality-audit-loop.md` for validation of all existing code.

The policy file is authoritative for every loop:

- Use `plan.model` during planning.
- Use `execute.model` during implementation or remediation.
- Use `validate.model` during checks and review.
- Use only the provider and models declared in the policy.
- Record provider, phase, model, commands, results, skipped checks, and residual risk
  in `.ai/progress.md` or the completion report.

If `loops/model-policy.yaml` is missing, malformed, or lacks a required phase, stop and
report the task as blocked. Do not claim completion until plan, execute, and validate
evidence is recorded.
Required checks must pass on the final snapshot. Missing tools/evidence, skipped
required checks, and unresolved Critical/High findings block approval. Use
`loops/run-quality-gate.mjs` and the project-owned `loops/quality-gate.json` for
automated checks; its success still requires the applicable manual reviews.
Use `loops/agents/security.md` and `loops/agents/performance.md` for relevant paths.
Never weaken a check, fabricate evidence, or approve a risk exception to make a task pass.
<!-- END AGENT LOOPS POLICY -->
