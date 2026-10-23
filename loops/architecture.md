# Shared AI Project Architecture

Use this document to understand where agent guidance belongs.

## Separation of concerns

- Rules define constraints and safety requirements.
- Loops coordinate understand, plan, implement, test, review, fix, and repeat.
- Role prompts provide focused review perspectives.
- Scripts and CI enforce executable checks.
- `.ai/` records task state so work can resume without rediscovery.
- `loops/project.md` owns project-specific scope, ownership, access rules, and budgets.
- `loops/quality-gate.json` is the source for executable required check commands.

Do not duplicate project architecture in role prompts. Link to the project's existing
README, architecture docs, and `loops/project.md` instead.

## Agent order

1. Read `AGENTS.md` and `AGENT_LOOPS.md`.
2. Read `.ai/plan.md` if the task is ongoing.
3. Read the relevant shared docs and `loops/project.md`.
4. Read `loops/quality-gate.md`, select one loop, and use applicable role prompts.
5. Inspect before editing; preserve unrelated working-tree changes.
6. Implement, verify, review, and update `.ai/progress.md`.
7. Apply the shared gate outcome to the final snapshot. Keep command results distinct
   from manual review evidence and from remote CI/merge enforcement.
