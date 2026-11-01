# Fresh-Context Design and Review Loop

Use this loop for every task, including small fixes, documentation changes, and
read-only reviews. It adds independent review to the selected task loop; it does not
replace implementation or quality gates. For tasks that make no changes, use the
review-only path rather than the before/after implementation sequence.

## Scale the design artifact

- For a small, clear task, the request or a short change brief is enough as the spec.
- For work with meaningful product, architecture, data, security, or ownership choices,
  write a spec with goals, constraints, behavior, affected paths, and acceptance criteria
  before implementation. Use brainstorming/drafting when trade-offs need discussion.
- Avoid a heavyweight spec when the request fully defines a narrow edit.

## Review before implementation

1. Create a fresh reviewer context, such as a new subagent or agent session. If the
   platform cannot create one, request an independent human review. Do not pass the
   author's earlier conversation, hidden reasoning, or rationale.
2. Provide only the request/brief/spec, relevant source and docs, and review criteria.
   Ask for ambiguous requirements, unstated assumptions, conflicts with source behavior,
   missed failure/boundary cases, and implementation risks. For substantial designs,
   also review clarity, code fit, and the implementation plan.
3. Keep the review read-only. Record findings and dispositions; resolve blocking gaps in
   the brief/spec and obtain any required user decision before implementation.

## Review the final change

1. After implementation, create a fresh reviewer context and provide the approved
   brief/spec, relevant source, and complete final diff, without the author's earlier
   discussion.
2. Ask for concrete correctness, regression, security, performance, maintainability,
   and requirement-fit findings. Limit categories to those relevant to the change.
3. The reviewer reports findings and does not edit. The author records each disposition,
   fixes accepted issues, and reruns affected checks after edits.

## Evidence and stop conditions

Record both review stages, reviewer context (for example, distinct agent/session or
independent human), the task/spec and diff snapshot reviewed, scope/material reviewed,
findings, and dispositions in `.ai/progress.md` or the completion report. Do not call a
review passed without an actual independent review. If fresh review cannot be run,
mark the gate blocked pending an independent human review. Do not substitute author
self-review. Keep the review proportionate: request/brief and changed lines can suffice
for a tiny change; substantial work needs relevant source, callers, and requirements.

## Review-only path

For a task whose requested result is only an assessment and makes no changes, the first
fresh-context reviewer performs the assessment and reports findings with source
evidence. A second distinct fresh-context reviewer receives the original request,
relevant source/evidence, and the first report (not the first reviewer's private context
or the author's rationale). They check support, coverage, and missed high-impact issues,
then report their own findings. The author records dispositions. Do not require design
approval or final-diff review when no change was made. Record Plan=scope/criteria,
Execute=`not applicable` (read-only), and Validate=both reviews plus assessment evidence.
Applicable source, security, and quality requirements remain in force; implementation
and code-test commands are not applicable when no change was made.
