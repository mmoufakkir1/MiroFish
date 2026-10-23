# Evidence Records

Use evidence records for investigations and for claims that materially affect a plan,
implementation, review, or approval. Keep records concise and link to source files or
task-local artifacts so another engineer can reproduce or challenge the conclusion.

```text
Question or claim:
Type: observation | inference | unknown
Evidence: path and line/symbol, command and relevant output, test, or artifact
Snapshot: commit/revision or relevant input/config fingerprint
Confidence and limits:
Next probe or verification:
```

An observation is directly present in source or produced by a recorded command. An
inference explains what observations suggest and must name its supporting evidence. An
unknown is a material question that available evidence has not answered. Confidence
does not replace evidence.

For command evidence, record the exact command, working directory, exit code, and only
the relevant redacted output. Include tool/version and input/config details when they
could change the result. For runtime or external-system evidence, record the target,
environment, permissions, side effects, and cleanup where applicable.

Save large logs, traces, and generated output as task-local artifacts and link to the
artifact with a brief summary. Bound output by scope and size; do not copy secrets or
personal data into `.ai/` files. Keep contradictory results and failed probes visible.

Evidence is current only for the snapshot and configuration it describes. Re-run
affected checks after relevant code, input, or configuration changes. A missing result
is not a passing result, and an inference alone cannot satisfy a required check.
