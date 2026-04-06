# Workflow: Write a Spec

Write an accurate E2E evaluation spec by first exploring the live application, then producing steps that match what actually exists in the UI. Never guess at labels, URLs, or page structure — look first, write second.

## Process

### Step 0: Check existing specs

Before doing anything, read all files in `e2e/specs/` (titles and step summaries). Check if an existing spec already covers the same or overlapping flow.

- **Exact match** (same flow, same starting point): update the existing spec in place — re-explore the app, refresh button labels/URLs/structure, rewrite steps based on current UI. Preserve the file name.
- **Partial overlap** (some steps overlap but different scope): tell the user what exists and ask whether to update the existing spec or create a new one.
- **No match**: create a new spec as normal.

This prevents spec duplication and keeps existing specs in sync with UI changes.

### Step 1: Understand the flow

The argument can be:
- A URL → use as starting point directly
- A natural-language description → figure out the URL yourself

**When given a description** (e.g., "admin login flow", "用户注册后创建频道"):
1. Read `e2e/env-playbook.md` to get service URLs and architecture
2. Read the project's route definitions to find matching pages/endpoints
3. Infer the starting URL from context — do NOT ask the user for it unless truly ambiguous (e.g., multiple apps on different ports and the description doesn't hint which one)

Only ask the user for clarification on things you genuinely cannot infer:
- If the description is too vague to determine which flow (ask which flow, not the URL)
- If the flow needs specific credentials not documented anywhere
- If the flow needs specific data state (e.g., empty database, existing users)

### Step 2: Determine data setup needs

If the flow requires specific data state, figure out how to achieve it by reading the project (or consulting `e2e/env-playbook.md` if it exists):

1. **Check available APIs** — read route definitions to find endpoints for creating/deleting data
2. **Check database access** — read docker-compose config for database service names and credentials
3. **Check for seed scripts** — look for existing reset/seed mechanisms

Write the `## Setup` section using natural-language descriptions of the needed state. The eval runner will translate these into concrete commands at execution time.

**Choosing between API and database:**
- Use API calls when an endpoint exists and produces the right data state (most common: user registration, resource creation)
- Use database operations when you need states that APIs can't produce (expired records, edge-case data, bulk cleanup)
- For clearing data, prefer a reset endpoint if one exists; otherwise describe the tables/collections to clear

### Step 2.5: Environment check

Before opening the browser, run the same worktree mismatch check as run-spec:
- If services are running from a different worktree, ask the user to restart from the current one
- If services aren't running at all, start them from the current worktree using the playbook

This is critical for write-spec because you're writing steps based on what you see — if the running app doesn't have the feature you're trying to spec, the whole workflow is pointless.

### Step 3: Explore the app

Open the starting URL with agent-browser and take a screenshot + snapshot:

```bash
agent-browser open <url> && agent-browser wait --load networkidle
agent-browser snapshot -i
agent-browser screenshot --screenshot-dir /tmp/
```

Read the screenshot to see the actual UI. Note:
- Page titles, headings
- Button labels (exact text)
- Input field placeholders
- Navigation items
- Layout structure

### Step 4: Walk through the flow

Interact with the app step by step, following the user's described flow. At each step:

1. Take a screenshot and snapshot before acting
2. Perform the action (click, fill, navigate)
3. Take a screenshot and snapshot after
4. Record what you see — exact text, exact labels, exact structure

Build up the spec as you go. Each step becomes an action/eval pair based on what you actually observed.

### Step 5: Write the spec

Write the spec to `e2e/specs/{name}.md` using this format:

```markdown
# [Flow Name]: [Short Description]

## Setup

- [Natural-language description of needed data state, e.g., "Clear all users from the database"]
- [Another setup action, e.g., "Create a test user with phone +8613800138000 via the registration API"]

## Steps

1. **action:** [what to do — use exact URLs, exact button labels]
   **eval:** [what should be visible — use exact headings, exact text, exact element descriptions]

2. **action:** [next interaction]
   **eval:** [expected result]
```

The `## Setup` section is optional — omit it if the flow works with whatever data state already exists.

Guidelines:
- Use exact text from the UI (button labels, headings, placeholder text)
- For credentials, describe how to obtain them (env vars, API calls, config) — never hardcode secrets
- Keep actions concrete: "click the 'Sign in' button" not "submit the form"
- Keep evals visual: describe what should be **seen**, not internal state
- One spec per user flow

### Step 6: Close browser and report

```bash
agent-browser close
```

Show the user the spec file path and a summary of what's covered.

If during exploration you discovered an **actual bug** (not a spec issue), mention it and offer:
> "Spotted a bug: [description]. Want me to fix it? (TDD: write test → fix → verify with `/e2e fix`)"

If yes, hand off to `workflows/fix-spec.md` with the newly written spec path.

## Success Criteria

- Spec file written to `e2e/specs/`
- Every action/eval pair is based on observed UI, not guesses
- Button labels, headings, and URLs match the live app
- Credentials are referenced by source, not hardcoded
- Flow is complete from start to end state
