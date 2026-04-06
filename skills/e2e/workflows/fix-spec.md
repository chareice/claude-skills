# Workflow: Fix Spec

Run a spec, fix any app bugs found in the codebase, and re-run to verify all fixes work. This is the "test → fix → verify" loop.

## Key principle

**Do NOT commit until the spec passes.** All code changes remain uncommitted until the final verification succeeds.

## Process

### Step 1: Initial run

Execute the spec using the full protocol from `workflows/run-spec.md` — this includes **all** Phase 0 checks (worktree mismatch detection, playbook startup checklist, known issues) and Phase 1 data setup, followed by step-by-step execution with screenshots and snapshots.

If the spec passes on the first run, report success and stop — nothing to fix.

### Step 2: Fix loop

Repeat until the spec passes or you decide to stop:

**2a. Collect evidence**

From the run results, collect all app-bug failures. For each bug, gather:
- What step failed, what was expected vs actual
- Screenshot and DOM snapshot
- **Frontend logs:** run `agent-browser console` to get browser console errors, JS exceptions, and failed network requests
- **Backend logs:** read the relevant service logs using the log access method documented in the playbook. Focus on the time window around the failure.

This combination — what the user sees (screenshot), what the page contains (DOM), what the browser reports (console), and what the server says (logs) — gives a complete picture.

**2b. Diagnose and fix (TDD)**

For each app-bug (in order of the spec steps):

1. Correlate the evidence: match the frontend error (e.g., 500 response) to the backend error (e.g., stack trace in logs) to locate the bug
2. Read the relevant source code
3. Understand the root cause — don't just patch the symptom
4. **Write a test that reproduces the bug** — unit test or integration test at the code level that fails with the current code. This test guards the fix permanently. Follow the project's existing test conventions (test framework, file location, naming).
5. **Fix the code** — make the minimal change needed so the new test passes
6. **Run the test** — confirm it passes. If not, iterate on the fix.
7. Do NOT commit yet — leave all changes (test + fix) uncommitted

Report each fix:
- `🔧 [bug description] — fixed in [file:line], test added in [test file:line]`

**2c. Re-run the spec from the beginning**

Run the full spec again (not just the failed step). This is critical because:
- A fix might break earlier steps
- A fix might reveal bugs that were previously masked

**2d. Decide whether to continue**

- **All steps pass** → exit loop, go to Step 3
- **New failures found** → continue fixing (back to 2a)
- **Same failure persists after fix attempt** → the fix didn't work. Revert that specific change, record it as unresolved, and decide: if there's a different approach to try, continue; if not, stop
- **No progress being made** → if the last two rounds fixed nothing new, stop — further attempts are unlikely to help. Exit to Step 3 with partial results

### Step 3: Final report

Close the browser: `agent-browser close`

**If all steps pass:**

Before committing, run the full project test suite to make sure the new tests pass and nothing else broke.

Then ask the user:
> "All N steps pass. Fixed M bugs, added M tests. Commit?"

If yes, create a single commit with all fixes and tests, listing each bug and its test in the commit message.

**If some issues remain:**

Report what was fixed and what wasn't:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Spec: [spec name]
Result: PARTIAL (N/M steps pass after 3 rounds)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Fixed:
  🔧 Step 2: Button click handler missing null check — fixed in src/app.rs:142, test in tests/app_test.rs:89
  🔧 Step 4: Wrong redirect URL after login — fixed in src/routes.rs:58, test in tests/routes_test.rs:34

Unresolved:
  ✗ Step 5: Dashboard chart doesn't render — root cause unclear

Code changes are uncommitted. Review with `git diff`.
```

## Rules

- Do NOT commit until the spec passes completely, or the user explicitly asks to commit partial fixes
- Fix app bugs only — script-errors and env-issues are handled by the regular run-spec workflow
- Make minimal fixes — don't refactor, don't improve, just fix the bug
- If a fix attempt makes things worse, revert it
- Stop when no progress is being made — don't loop forever on the same bug
