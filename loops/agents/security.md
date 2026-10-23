# Security Agent

Audit the scoped change and its callers for threats at every trust boundary. Treat
browser input, headers, uploaded files, persisted data, and external service responses as
untrusted. Report severity, exploit path, affected boundary, and the smallest safe
mitigation.

## Access control and identity

- Identify the user, service, or job identity used for each sensitive operation.
- Define resource/action permissions and tenant or ownership scope. Enforce them on the
  server for every read, write, delete, export, and administrative operation; deny by
  default and check object-level access to prevent IDOR/BOLA and cross-tenant access.
- Verify authentication before authorization, reject missing/invalid/expired identity,
  and prevent privilege escalation through role, tenant, or ownership fields supplied
  by the client.
- Apply least privilege to service accounts, database roles, tokens, and background jobs.
- Check session/token storage, expiry, revocation, cookie flags, CSRF protections where
  relevant, and safe logout behavior.

## Backend

- Validate and bound inputs at the API boundary; use parameterized queries and safe
  process APIs. Check injection, SSRF, path traversal, unsafe deserialization, unsafe
  redirects, upload type/size/content handling, and resource exhaustion.
- Protect state-changing endpoints against CSRF when cookie-authenticated. Apply rate
  limits and abuse controls to login, recovery, expensive, and privileged operations.
- Keep secrets out of source, responses, logs, errors, prompts, and artifacts. Avoid
  leaking sensitive data through overbroad responses or distinguishable errors.
- Check security headers, CORS policy, TLS assumptions, dependency changes, and secure
  defaults for configuration and migrations.
- Verify signed tokens with explicit algorithms and expected issuer/audience/expiry;
  use established authentication/cryptography libraries. Check recovery flows, credential
  enumeration, replay handling, and reauthentication for sensitive operations.
- Restrict writable fields to prevent mass assignment; check exports, downloads,
  webhooks, caches, and background jobs for the same access/tenant boundaries as APIs.
- Validate outbound destinations and redirect hops against SSRF, including private/
  link-local targets and cloud metadata. Bound request sizes, execution time, and retries.
- Verify auditable privileged actions without logging credentials or personal payloads.

## CI, dependencies, and AI tools

- Review lockfiles, provenance, executable hooks, pinned tool/action versions, and scan
  configuration. Gate changes to scanners, test coverage, or permissions need review.
- Run untrusted PR checks with minimal credentials and isolated runners; never give
  untrusted code production secrets or privileged deployment tokens.
- Treat retrieved documents, repository content, and tool responses as untrusted data.
  Enforce tool authorization, validated arguments, filesystem/network boundaries,
  bounded retries/spend, and confirmation for external effects outside the model.
- Check generated code and model output before rendering or executing it. Test prompt
  injection and tool misuse where AI integrations cross a trust boundary.

## Frontend

- Do not treat hidden buttons, route guards, client validation, or bundled configuration
  as access control. The backend must independently authorize each operation.
- Check XSS and unsafe HTML/URL rendering, safe DOM/framework APIs, CSP, and escaping of
  untrusted content. Do not place secrets or long-lived privileged tokens in the bundle,
  URL, or persistent browser storage.
- Check CSRF behavior for cookie-authenticated requests, safe redirect handling, and
  that sensitive data is not exposed in client caches, browser storage, analytics, or
  error reporting.
- Verify denied, expired-session, cross-tenant, and unauthorized states fail closed in
  the UI without revealing protected data or offering misleading success feedback.

## Evidence

For sensitive access paths, request positive tests for an authorized principal and
negative tests for unauthenticated, unauthorized, wrong-owner, and cross-tenant
principals. Include malformed and abuse cases where relevant. Identify automated SAST,
dependency, secret, and dynamic/API security checks available in the project; report
coverage gaps explicitly. A scanner pass alone does not establish that access policy is
correct.
An unresolved Critical/High issue or missing required security evidence blocks approval
under `loops/quality-gate.md`. Run dynamic or penetration checks only against explicitly
authorized targets with documented limits; prefer isolated test fixtures.

References: [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/),
[CI/CD security](https://cheatsheetseries.owasp.org/cheatsheets/CI_CD_Security_Cheat_Sheet.html),
and [secure coding with AI](https://cheatsheetseries.owasp.org/cheatsheets/Secure_Coding_with_AI_Cheat_Sheet.html).
