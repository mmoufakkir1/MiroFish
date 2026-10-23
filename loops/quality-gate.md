# Shared Code Quality Gate

Every loop must apply this contract. In a consuming repository it is installed as
`loops/quality-gate.md`. Commands belong in `loops/quality-gate.json`;
`loops/project.md` explains scope, ownership, access policy, budgets, and applicability.

## Scope and evidence

- For ordinary code changes, inspect the complete diff plus callers, dependencies,
  security boundaries, and affected legacy paths. Run the project's required checks.
- For a request to validate all code, use `quality-audit-loop.md`: inventory every owned
  language, service, frontend, backend, script, infrastructure definition, and dependency.
  Run checks over the whole repository. List excluded generated/vendor paths, sampled
  review areas, and unexamined components; do not claim complete coverage from sampling.
- Record the code snapshot, check command/arguments, scope, exit code, tool/config version
  when relevant, and redacted evidence. A planned check, printed command, or AI judgment
  is not an executed check. Evidence must apply to the final code; rerun affected checks
  after edits. Never rewrite tests, thresholds, fixtures, or scanner rules just to pass.
- Existing failures remain visible. A failed required check blocks the gate even when
  pre-existing. Record diagnosis and scope rather than hiding it behind a clean diff.

## Required review areas

| Area | Evidence required when applicable |
| --- | --- |
| Correctness | Formatting/lint/types/build plus behavioral tests for success, failure, boundary, and regression cases; interfaces and data contracts remain compatible. |
| Backend | API validation, trusted authentication/authorization, object and tenant isolation, transactions, migrations/rollback, bounded queries, concurrency, cancellation, and cleanup. |
| Frontend | Runtime user flow, loading/error/denied states, responsive and keyboard behavior, safe rendering, session handling, client data exposure, bundle/network/render impact. |
| Security | Read `loops/agents/security.md`; review threats and access policy, run configured secret/dependency/static/config scans, and exercise denied and abuse cases. |
| Efficiency | Read `loops/agents/performance.md`; examine complexity, I/O, query count, allocations, payload/bundle size, caching correctness, and bounded work. Measure relevant risks against a baseline/budget. |
| Supply chain and CI | Lockfiles, dependency provenance, least-privilege CI credentials, untrusted PR isolation, pinned tooling, artifact identity, and deploy permissions. |
| AI/tool integration | Treat retrieved content and tool output as data; validate generated arguments/output; enforce tool permissions outside the model; bound execution, retries, spend, and side effects. |

Use project tooling and documented versions. Avoid adding scanners or dependencies
without a relevant gap. A security scan does not replace code review or access tests.
Docs-only work needs applicable content/link/script checks; unrelated application tests
may be marked not applicable with a concrete reason.

## Efficiency decisions

Define a representative scenario, dataset size, environment, and metric before
optimizing. Capture baseline and after-change latency, memory, CPU, query/I/O count,
or bundle size as relevant. Use repeatable measurements and project budgets; do not
claim a speedup from intuition or a single noisy timing. Avoid caches, parallelism,
or abstraction that weaken access checks, correctness, resource limits, or cleanup.

Review every change for avoidable work. Require a benchmark/load check when changing
a hot path, large-data query, concurrency limit, cache, asset bundle, or project budget.
If a required baseline or environment is unavailable, report that gate as blocked.

## Gate outcomes

Use `pass`, `fail`, `blocked`, or `not-applicable` for each review/check.

- **Pass:** applicable required commands pass on the final snapshot, required runtime
  and review evidence exists, and no unresolved Critical or High findings remain.
- **Fail:** a check or requirement fails, including an unsafe access boundary or a
  breached performance budget. Fix it and rerun the affected checks.
- **Blocked:** a required tool, command, environment, permission, or evidence is missing.
  State the exact prerequisite and next action; never convert it to pass.
- **Not applicable:** the check does not apply to the documented scope. Explain why;
  unavailable tools and failed checks are not reasons for this outcome.

A skipped required check prevents `Status: complete`. A reason explains a skip; it
does not waive it. Medium/Low findings need an owner and disposition. Exceptions need
explicit documented risk acceptance by the appropriate project owner, affected scope,
justification, expiry, and compensating controls. Agents must not approve their own
exceptions or weaken a gate. Repository audit readiness remains blocked by unresolved
repository blockers; a narrower task can report its bounded result without claiming
the entire repository is healthy.

`Status: complete` means the requested scope passed all applicable gates. Use
`blocked` for unmet required gates and `deferred` for explicitly postponed scope.
A read-only review may finish reporting findings with a failed gate; it must not
describe the code as approved or ready to ship.

## Executable gate

`loops/run-quality-gate.ps1` runs the required checks in `loops/quality-gate.json`.
All checks selected for a scope are mandatory. It refuses missing/empty/invalid
configuration, missing executables, invalid working directories, and empty scope
selection. Commands must be trusted project configuration; never execute a manifest
from an untrusted PR on a host with production credentials.

Use PowerShell 7 and Git:

The JSON object contains integer `version: 1` and a non-empty `checks` array. Every
check has these fields; unknown fields and duplicate IDs are rejected:

| Field | Meaning |
| --- | --- |
| `id` | Unique lowercase name using letters, digits, and hyphens. |
| `category` | One of format, lint, types, tests, build, secrets, dependencies, static, integration, performance, docs, config. |
| `scopes` | Non-empty array containing change, repository, or both. |
| `executable` | Trusted installed executable or absolute executable path. |
| `arguments` | String array passed as separate arguments; no implicit shell evaluation. |
| `workingDirectory` | Existing relative directory within the project, typically `.`. |
| `timeoutSeconds` | Integer from 1 through 3600. |

Migrate verified commands from existing project documentation into this manifest and
review the change. For shell scripts or Windows command wrappers, explicitly invoke
the appropriate trusted interpreter. Keep credentials out of arguments/configuration.
The runner never installs tools or downloads packages. Configure each applicable gate
category; a non-empty manifest alone is not proof that all required areas are covered.
Each command must return nonzero for blocking findings, failed tests, or breached
budgets. Check wrappers must propagate failures and reject unexpectedly empty test
discovery; a scanner that prints findings but exits zero is not a working blocking gate.

```powershell
pwsh -File loops/run-quality-gate.ps1 -ProjectRoot . -Scope change
pwsh -File loops/run-quality-gate.ps1 -ProjectRoot . -Scope repository
pwsh -File loops/run-quality-gate.ps1 -ProjectRoot . -Scope change -Verify
```

The runner records command outcomes and a content fingerprint in
`.ai/quality-gate-result.json`. `-Verify` refuses evidence for another scope or stale
code/configuration. It excludes `.ai/` task state and Git-ignored files from the
fingerprint; checks must cover relevant ignored/generated/runtime inputs separately.
The snapshot requires an existing commit at the repository root and refuses symlink,
junction, or submodule paths; projects using those need explicit coverage rather than
silently excluding them. Verification checks source/config freshness, not changes to
external services or tool installations; rerun when those inputs change.
The JSON report is local task evidence, not a signed attestation; CI must execute
trusted checks rather than accepting an uploaded report as approval.
Raw output is drained, not persisted, to avoid accidental secret disclosure; configure
tools to produce redacted diagnostic reports and link them in the completion evidence.

Exit codes: `0` automated checks passed, `1` a check failed/timed out, `2` configuration
or execution was blocked, `3` the snapshot/evidence is stale. Exit `0` does not replace
manual security, correctness, or efficiency review. The runner does not enforce a
remote merge policy; projects must install required CI checks and branch protection.

## Completion evidence

Report `Status`, `Scope`, `Snapshot`, requirements, changed files, behavior impact,
gate results, positive and negative evidence, security findings, performance evidence,
commands/results, skipped or inapplicable checks with reasons, and residual risk.
Identify missing project configuration and CI enforcement instead of claiming they
are installed.

Security references: [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/),
[CI/CD security](https://cheatsheetseries.owasp.org/cheatsheets/CI_CD_Security_Cheat_Sheet.html),
and [secure coding with AI](https://cheatsheetseries.owasp.org/cheatsheets/Secure_Coding_with_AI_Cheat_Sheet.html).
