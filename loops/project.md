# Project Loop Config

## Identity

- Project: MiroFish
- Organization: projectPlan
- Stack: Frontend/backend application

## Paths

`frontend`, `backend`, `README.md`, `Dockerfile`, `package.json`

## Validation

`npm run build`; use `npm run setup:all` and `npm run dev` only for environment validation.

Use the shared template's scope, evidence, blocker, and completion rules. If a command
is unavailable, report it as skipped with the reason; do not claim it passed.

## Ownership

Keep changes in the layer that owns them according to the existing project structure.
Do not move behavior across frontend, backend, database, automation, or infrastructure
boundaries without documenting the decision.

## Documentation

Update the README or the nearest project documentation when commands, architecture,
user-visible behavior, deployment, or data contracts change.
