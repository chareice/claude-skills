# Workflow: Suggest Specs

Analyze the project's codebase to identify testable user flows, compare against existing specs, and recommend what to cover next.

## Process

### Step 1: Parallel discovery (use Agent tool)

Launch two subagents in parallel:

**Agent A: Discover user-facing flows** — scan the project's codebase and return a structured list of all user-facing flows:

- **Routes/pages** — read route definitions, page components, controller actions to find all user-accessible endpoints
- **Auth flows** — login, logout, registration, password reset, OTP verification
- **CRUD operations** — for each resource: create, read, update, delete flows
- **Admin/management** — admin panels, dashboards, settings pages
- **Key user journeys** — multi-step flows that combine multiple pages (e.g., signup → onboarding → first action)

For each flow, return: name, entry point (URL), complexity, risk level (handles money? auth? data deletion?)

**Agent B: Inventory existing specs** — read all files in `e2e/specs/` and return a structured list:

- What flow each spec covers
- Which URLs/pages it touches
- Number of steps

Wait for both agents to complete before proceeding.

### Step 2: Gap analysis

Compare discovered flows against existing specs. Classify each flow:

- **Covered** — an existing spec covers this flow adequately
- **Partial** — a spec touches this flow but doesn't cover it fully (e.g., tests listing but not creation)
- **Uncovered** — no spec covers this flow

### Step 3: Prioritize recommendations

Rank uncovered/partial flows by priority:

**High priority** (suggest first):
- Auth flows (login, logout, registration) — if broken, nothing else works
- Flows that handle money, payments, or billing
- Flows that modify/delete data irreversibly
- Core user journeys (the "happy path" most users follow)

**Medium priority:**
- CRUD operations for main resources
- Admin/management pages
- Settings and configuration flows

**Low priority:**
- Read-only pages with no interaction
- Edge-case flows (error states, empty states)
- Rarely used features

### Step 4: Print the report

```
E2E Coverage Report

Discovered flows: N
Existing specs:   M
Coverage:         X% (covered / total)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

HIGH PRIORITY (uncovered)

  1. [Flow name]
     Entry: [URL]
     Why: [reason it's important]
     Suggested spec: /e2e write [description]

  2. ...

MEDIUM PRIORITY (uncovered)

  ...

PARTIAL COVERAGE (existing spec needs expansion)

  - [spec file] — covers [X] but misses [Y]

COVERED (no action needed)

  - [flow] ← [spec file]
```

### Step 5: Offer to write

After printing the report, ask:
> "Want me to write the top-priority spec now?"

If yes, hand off to the write-spec workflow with the suggested description.
