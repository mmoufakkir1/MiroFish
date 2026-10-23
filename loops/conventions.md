# Shared Agent Conventions

- Make the smallest coherent change that satisfies the request.
- Prefer existing project patterns over new abstractions and dependencies.
- Keep frontend, backend, database, automation, and infrastructure ownership boundaries intact.
- Treat external input, credentials, file paths, commands, and client permissions as untrusted.
- Define who may perform each sensitive action on each resource; enforce authorization on
  the server for every request, default to deny, and grant only the access required.
- Treat frontend route guards, hidden controls, and client-side validation as usability
  features, never as authorization or a security boundary.
- Never expose secrets in code, logs, prompts, or `.ai/` state.
- Preserve unrelated user changes; do not reset, force-checkout, or delete outside scope.
- Record assumptions and decisions when they affect architecture, security, data, or deployment.
- Report commands actually run, failures, skipped checks, and residual risk.
