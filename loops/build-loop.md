# Build Loop

Use with the target repository's `loops/project.md` for each page or feature.
Read `loops/agent-development-loop.md` and `loops/quality-gate.md`; their gate rules
apply throughout this loop.

## Model policy

Before starting, read `loops/model-policy.yaml`. Use its `plan.model` for planning,
`execute.model` for implementation, and `validate.model` for verification. Use only
the declared provider and models; record each phase and model in `.ai/progress.md` or
the completion report. If the policy is missing or invalid, stop and mark the loop
blocked.

1. Plan the page or component structure, data needs, affected routes, and validation scope.
   Define API/access boundaries, untrusted content, denied states, and relevant
   render/network/bundle budgets before implementation.
2. Scaffold the requested behavior with realistic product-specific content; do not leave lorem ipsum or placeholder company text.
3. Apply the project's established design tokens, component patterns, responsive breakpoints, and accessibility conventions.
4. Verify the rendered UI at desktop and mobile widths when the change affects UI. Check layout, overflow, contrast, focus states, loading/error states, and the primary workflow.
5. Fix issues found during verification and repeat the affected checks.
6. Run the project's required lint, formatting, typecheck, tests, and build checks from `loops/project.md`; fix failures in touched files before handoff.
7. Repeat for the next page or component until the requested scope is complete.

For a full site, also verify responsive behavior, semantic HTML and alt text, keyboard navigation, SEO metadata, 404 behavior, optimized images, shared navigation/footer, and working form feedback where applicable.

Complete only when the requested surface has positive/negative evidence and all
applicable gates in `loops/quality-gate.md` pass. Report security review and efficiency
evidence, including unavailable required visual checks as blockers.
