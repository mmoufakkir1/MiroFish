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

1. Classify the surface as a component, an application screen, or a marketing/content
   page. Choose acceptance criteria for that surface; do not apply landing-page
   conventions to an application screen.
2. Plan the component/screen structure, data needs, affected routes, and validation
   scope. Define API/access boundaries, untrusted content, denied states, and relevant
   render/network/bundle budgets before implementation.
3. Inspect the existing screen and record the content and behavior that must survive.
   For a redesign or restyle, include facts, copy, routes, links, form fields, handlers,
   IDs, test selectors, data calls, and analytics hooks. Change or remove these only
   when the request authorizes it; check the list against the final diff.
4. Scaffold the requested behavior with realistic product-specific content; do not
   leave lorem ipsum or placeholder company text. Apply the project's established
   design tokens, component patterns, responsive breakpoints, and accessibility
   conventions.
5. For substantial multi-part UI work, implement one representative component or
   screen first. Render it and obtain a fresh-context review of the interaction and
   visual direction before repeating that pattern across the remaining scope. Resolve
   blocking findings or record their disposition before continuing.
6. Verify rendered UI at the target desktop and mobile widths. Check layout, overflow,
   contrast, keyboard and `:focus-visible` behavior, loading/error/denied states, and the
   primary workflow. For interactive controls, review default, hover, focus-visible,
   active, disabled, loading, error, and success states when each applies.
7. Fix issues found during verification and repeat the affected checks.
8. Run the project's required lint, formatting, typecheck, tests, and build checks from
   `loops/project.md`; fix failures in touched files before handoff.
9. Repeat for the next page or component until the requested scope is complete.

For a full site, also verify responsive behavior, semantic HTML and alt text, keyboard navigation, SEO metadata, 404 behavior, optimized images, shared navigation/footer, and working form feedback where applicable.

Complete only when the requested surface has positive/negative evidence and all
applicable gates in `loops/quality-gate.md` pass. Report security review and efficiency
evidence, including unavailable required visual checks as blockers.
