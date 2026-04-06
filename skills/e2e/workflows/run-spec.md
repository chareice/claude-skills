# Workflow: Run a Spec

Execute the evaluation script at the given path step by step using agent-browser.

## Protocol

1. Read `e2e/env-playbook.md` (if it exists) to learn the environment
2. Run environment pre-checks based on the playbook
3. Read the evaluation script file at the given path
4. If a `## Setup` section exists, execute data preparation before any steps
5. Execute each step in order
6. On failure: diagnose, attempt recovery, record findings
7. After all steps: write a run report with self-reflection

### Phase 0: Environment pre-check

Read `e2e/env-playbook.md` if it exists. This file describes the test environment architecture, how to start it, and known issues with fixes.

**Worktree mismatch check** (for projects using git worktrees):
- Detect which directory the running services were started from (e.g., inspect `docker compose ps` output, check container labels, or examine process working directories)
- Compare against the current working directory
- If they differ, **always** ask the user — never assume it's OK to continue:
  > "Services are running from `[other worktree]`, you're in `[current worktree]`. Restart from here?"
  - If yes: stop the old services using the playbook's stop method, then decide restart vs rebuild:
    - Check `git diff` between the old and current worktree for infrastructure-related changes (container definitions, dependency files, migration files, build configs)
    - **No infra changes**: simple restart using the playbook's start command
    - **Infra changes found**: full rebuild using the playbook's build command (if documented) or start command with build flag
    Then continue
  - If no: stop — do NOT proceed with mismatched services

**If the playbook has a Startup Checklist**, run each check:
- Report: `⚙ [check name] — [result]`
- If a service isn't running, use the playbook's start command to bring it up
- If a known issue is detected, apply the documented fix automatically

**If no playbook exists**, do a basic check:
- Try to reach the first URL mentioned in the spec
- If unreachable, look for docker-compose files in the project and suggest starting services

**If pre-checks fail and cannot be recovered**, stop and report. Do not proceed to steps.

### Phase 1: Data preparation (Setup section)

If the spec has a `## Setup` section, execute it before opening the browser. Setup items are natural-language descriptions of the data state needed. Translate them into concrete commands by reading the project context:

- **Prefer API calls** when an endpoint exists for the operation (e.g., user registration, creating resources). Check the project's route definitions or API docs to find suitable endpoints.
- **Fall back to direct database operations** when no API covers the needed state (e.g., setting a user as expired, creating edge-case data). Use the database CLI method documented in the playbook.
- **For clearing data**, check if the project has a reset/seed endpoint. If not, use database truncation via the playbook's database CLI.

To figure out the right approach, read the project's codebase (or consult the playbook's Architecture section if it documents available APIs and database access methods):
- Check route files for available API endpoints
- Check docker-compose config for database service names and credentials
- Check for existing seed/reset scripts

Report each setup action as it executes:
- `⚙ [setup description] — via [method used]`
- On failure: classify as env-issue, stop, and report

### For each step:

**Execute the action:**
- Translate the natural-language action into agent-browser CLI commands via Bash
- Common mappings:
  - Navigate: `agent-browser open <url> && agent-browser wait --load networkidle`
  - Get element refs: `agent-browser snapshot -i`
  - Click: `agent-browser click @eN`
  - Fill input: `agent-browser fill @eN "text"`
  - Press key: `agent-browser press Enter`
  - Wait: `agent-browser wait --text "expected text"` or `agent-browser wait @eN`
- Always run `agent-browser snapshot -i` after navigation or clicks to get fresh refs

**Collect evidence:**
- Take a screenshot: `agent-browser screenshot --screenshot-dir e2e/evidence/`
- Read the screenshot image (using the Read tool) to see what the page looks like
- Take a DOM snapshot: `agent-browser snapshot -i` to see interactive elements

**Evaluate the condition:**
- Compare what you see (screenshot + DOM snapshot) against the eval condition
- For visual state (layout, visibility): rely on the screenshot
- For content (text, elements, structure): rely on the DOM snapshot
- Determine PASS or FAIL

**Record observation:**
After evaluating, write a brief observation of what you actually saw — key content, data values, element counts, anything noteworthy. This is not just pass/fail, it's what the page contained at that moment. Keep it to one line for passed steps, more detail for failed steps.

**Report immediately:**
- PASS: `✓ [step name] — [brief observation, e.g., "Dashboard loaded, Users=1, Active=1, Models=0"]`
- FAIL: `✗ [step name] — [what went wrong + what was observed]`

### On failure: collect logs, diagnose, and recover

When a step fails, do NOT immediately stop. First collect additional evidence:

- **Frontend logs:** run `agent-browser console` to get browser console errors, JS exceptions, failed network requests
- **Backend logs:** check service logs for the time window around the failure using the log access method documented in the playbook

Then classify the failure:

1. **Diagnose** — using screenshot + DOM + frontend logs + backend logs:
   - **script-error**: The evaluation script itself is wrong (wrong selector, wrong password, wrong URL, outdated expectation). Evidence: the app looks healthy but the script's assumption doesn't match reality.
   - **app-bug**: The application has an actual defect. Evidence: the app shows an error, crashes, renders incorrectly, or behaves contrary to its own design intent. Include relevant log lines in the report.
   - **env-issue**: Environment problem (service not running, network error, timeout). Evidence: connection refused, 502, blank page.

2. **Attempt recovery** (only for script-error and env-issue):
   - For script-error: figure out the correct value/selector/expectation from what you see, apply the fix, and **retry the step once**. Record what you changed.
   - For env-issue: check the playbook for a matching known issue and apply its fix. If not in the playbook, try to diagnose and fix it yourself (restart service, wait for health, etc.). Retry once. If recovery succeeds, flag this as a **playbook candidate** — a new issue worth adding.
   - For app-bug: do NOT attempt to fix. Record the bug and stop.

3. **Record** — only record findings that are actionable (see below).

### After all steps complete (or on unrecoverable failure):

1. Close the browser: `agent-browser close`

2. **Always** write a run log to `e2e/evidence/runs/YYYY-MM-DDTHH-MM-SS-[spec-name].md` (one file per run). The file records the full run with observations:

```markdown
# [spec name] | PASS/FAIL (N/M)

**Time:** YYYY-MM-DD HH:MM:SS
**Worktree:** [current directory]

## Steps

- ✓ Step 1: [name] — [observation: key content, data values, element state]
- ✓ Step 2: [name] — [observation]
- ✗ Step 3: [name] — [what failed + what was observed]
  - Type: [script-error/app-bug/env-issue]
  - Recovery: [what was done, if any]

## Environment

- [any notable env actions: worktree restart, playbook fix, etc.]
- [or "No issues" if clean]
```

3. **Only if there were issues**, write a run report to `e2e/evidence/report.md` (overwrite if exists). All-green runs don't need a report.

The report only contains actionable findings — things that need someone to do something:

```markdown
# Evaluation Run Report

**Spec:** [spec name] | **Time:** [ISO timestamp] | **Result:** PASS / FAIL

## Script Corrections

Changes that should be made permanent in the evaluation script:

- **Step N:** [what was wrong] → [what it should be]. Reason: [why, e.g. "password is environment-specific, not hardcoded"]

## App Bugs

Defects in the application that need developer attention:

- **[Bug title]:** [one-line description]. Repro: step N of this spec. Evidence: [screenshot filename].

## Environment Notes

Problems with the test environment worth knowing about (only if non-obvious):

- [e.g. "Gateway takes ~2min to become healthy after compose up, health check needed before running specs"]
```

Omit any section that has no entries. An all-green run with no issues = no report file at all.

3. Print summary to console:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Spec: [spec name]
Result: PASS / FAIL (N/M steps)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If there were issues, append a brief list:
```
Findings:
  - script-error: Step 2 password was hardcoded, recovered by reading compose config
  - app-bug: Step 4 Models page shows 500 error on empty state
Report: e2e/evidence/report.md
```

4. **Script corrections** — if any were found:
   - **Auto-fix mode (default):** Apply corrections to the spec file immediately, then report what was changed.
   - **Report-only mode:** Just list the corrections in the report. Do not modify the spec file.

5. **App bugs** — if any were found:
   - **Auto-fix mode (default):** Immediately hand off to `workflows/fix-spec.md` with the spec path. The fix workflow uses TDD (write test to reproduce → fix → verify with e2e).
   - **Report-only mode:** Just list the bugs in the report. Do not attempt fixes.

6. **Playbook candidates** (env issues that were solved but not yet in the playbook) — if any:
   - **Auto-fix mode (default):** Append each new entry to the Known Issues section of `e2e/env-playbook.md` automatically:
     ```markdown
     ### [Short title]
     **Symptom:** [what you observed]
     **Fix:** [the command or action that resolved it]
     ```
   - **Report-only mode:** Just note them in the report. Do not modify the playbook.

> **Mode determination:** Default is auto-fix. If the user invoked this via `/e2e report <spec>`, use report-only mode.

## Rules

- Be honest — if the eval condition is ambiguous or only partially met, report it as FAIL
- Do NOT modify the evaluation script during execution without recording it as a script-error
- Do NOT skip steps
- If a step's action requires API calls (e.g. to get a debug OTP code), make them via Bash curl
- Retry at most once per failed step — if recovery fails, stop and report
- Clearly distinguish script-error from app-bug — the whole point is to know whether the spec or the app needs fixing
