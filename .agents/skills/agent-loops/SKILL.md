---
name: agent-loops
description: Apply shared correctness, security, and efficiency gates in repositories configured with AGENT_LOOPS.md and loops/project.md.
---

# Agent Loops

Use this skill for repository work in a project that contains `AGENT_LOOPS.md` and
`loops/project.md`.

Before acting:

1. Read `AGENTS.md`, `AGENT_LOOPS.md`, the selected loop, `loops/project.md`, and
   `loops/model-policy.yaml`, plus `loops/agent-development-loop.md` and
   `loops/quality-gate.md`.
2. Use the model declared for the current phase in `loops/model-policy.yaml`:
   `plan.model` for planning, `execute.model` for implementation, and `validate.model`
   for verification.
3. Use only the provider and models declared by the policy. If the policy is missing,
   malformed, or lacks a required phase, stop and report the task as blocked.
4. Record the provider, phase, model, commands, results, skipped checks, and residual
   risk in `.ai/progress.md` or the completion report.

Complete all three phases before claiming completion. Preserve unrelated working-tree
changes and use the project's validation matrix from `loops/project.md`.
Use `loops/quality-audit-loop.md` for requests to validate all existing code; a change
gate covers only its documented scope. Read `loops/agents/security.md` and
`loops/agents/performance.md` for relevant access, threat, and efficiency reviews.

Run `node loops/run-quality-gate.mjs` with the project-owned `loops/quality-gate.json`
when configured. Verify evidence on the final snapshot. Required skips, missing
tools/evidence, and unresolved Critical/High findings prevent approval; explanations
do not waive gates. A runner pass still needs applicable runtime and manual review.

When behavior, ownership, or a failure cause is materially unclear, use
`loops/investigation-loop.md` before implementation. Record observations, inferences,
and unknowns with sources using `loops/evidence.md`; bound probes and outputs, and carry
verified findings into one implementation loop. Keep raw artifacts task-local and
redact sensitive data.

For automatic model selection, run the project-local Node.js launcher:
`node loops/run-loop-phase.mjs`.
It reads the project policy and launches the selected phase with Codex, Claude, or
OpenCode when the policy provider matches that CLI. An already-running agent session
cannot be switched by a loop file; start a new phase through the launcher instead.
