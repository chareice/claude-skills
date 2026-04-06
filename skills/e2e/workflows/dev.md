# Workflow: Dev

One-stop workflow for newly developed features: write spec → run → fix bugs → verify. Loops until green or user decides to stop.

## Process

### Step 1: Write the spec

Follow `workflows/write-spec.md` to create or update a spec for the described feature. This includes environment check, exploring the live app, and writing action/eval pairs.

### Step 2: Run the spec

Follow the full run protocol from `workflows/run-spec.md` (env pre-check, data setup, step-by-step execution with observations).

### Step 3: Evaluate results

- **All steps pass** → go to Step 4
- **Script errors only** (spec doesn't match UI) → fix the spec in place, re-run from Step 2
- **App bugs found** → go straight into the fix loop from `workflows/fix-spec.md` (TDD: write test → fix → re-run). Do NOT ask "want me to fix?" — the whole point of `/e2e dev` is to fix what you find.

After fix loop completes (spec passes or no more progress), continue to Step 4.

### Step 4: Wrap up

Close the browser: `agent-browser close`

Write the run log to `e2e/evidence/runs/`.

Report:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/e2e dev: [feature description]
Spec: e2e/specs/[name].md
Result: PASS / PARTIAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Spec written: [new / updated existing]
Bugs fixed: N (with tests)
Unresolved: M
```

If all green and there are code changes, ask:
> "Spec passes, N bugs fixed with tests. Commit all changes?"

## Rules

- Do NOT pause between write/run/fix — this is a continuous flow
- Script errors are self-corrected silently (fix spec, re-run)
- App bugs trigger TDD fix immediately, no confirmation needed
- Only stop to ask the user when genuinely stuck or when ready to commit
