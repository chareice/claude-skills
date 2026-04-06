# Workflow: Setup Project

Set up or update the E2E evaluation system in the current project.

Three modes based on arguments:

- **No extra args** (`/e2e setup`) — full initialization. Idempotent: skips what exists, creates what's missing.
- **With description** (`/e2e setup 换了LLM模型`) — targeted update. Re-read project config and update the relevant parts of `e2e/env-playbook.md` based on what the user described.
- **With PR number** (`/e2e setup #42` or `/e2e setup PR 42`) — read the PR diff via `gh pr diff 42`, identify infrastructure-related changes (docker-compose, .env, dependencies, ports, new services, etc.), and update the playbook accordingly. Only touch playbook sections affected by the diff.

## Process (full initialization)

### Step 1: Inventory existing state

Check which components already exist and build a checklist:

- [ ] `e2e/specs/` directory
- [ ] `e2e/evidence/` directory
- [ ] `e2e/.gitignore`
- [ ] `e2e/env-playbook.md`

Report what's already in place and what will be created. Then ask the user:

> "Here's what I found and what I plan to do. Anything you want to adjust before I proceed?"
>
> - Existing: [list what exists]
> - Will create: [list what's missing]
> - Questions: [any ambiguities, e.g., "I see two docker-compose files — which one is for dev?"]

Proceed after the user confirms or provides clarification.

## Process (targeted update)

If the user provided a description of what changed:

1. Read `e2e/env-playbook.md`
2. Re-read the relevant project config files (docker-compose, .env, route definitions, etc.) based on what the user described
3. Update the affected sections of the playbook — do NOT rewrite unrelated sections
4. Run the Startup Checklist to verify the updated config works
5. Report what changed

Examples:
- "换了LLM模型" → re-read .env and LLM config, update Architecture and Data Access sections
- "加了新服务" → re-read docker-compose, update Architecture and Startup Checklist
- "数据库迁移了" → update Database section and Data Access methods

Then continue to the smoke test (Step 4 below) to verify.

## Process (PR-based update)

If the user provided a PR number (e.g., `#42`, `PR 42`):

1. Read the PR diff: `gh pr diff 42`
2. Identify infrastructure-related changes in the diff:
   - docker-compose / compose files (new services, port changes, env vars)
   - .env / .env.example (new config keys)
   - Dependency files (new packages that might need install steps)
   - Database migrations (schema changes affecting data access)
   - Route changes (new API endpoints relevant to data setup)
   - Logging config changes
3. Read `e2e/env-playbook.md`
4. Update only the affected sections based on the diff — present changes to the user for confirmation before writing
5. If the PR adds new user-facing flows, suggest writing new specs:
   > "This PR adds [feature]. Want me to write an e2e spec for it?"

Then continue to the smoke test (Step 4 below) to verify.

### Step 2: Create directory structure (if missing)

```
e2e/
├── specs/           # Evaluation scripts (committed)
├── evidence/        # Screenshots and reports (gitignored)
└── .gitignore       # Contains: evidence/
```

Skip if directories and `.gitignore` already exist.

### Step 3: Generate environment playbook (if missing)

Skip if `e2e/env-playbook.md` already exists.

**Auto-discover first, ask second.** Search the project for infrastructure clues:

- docker-compose / compose.yaml files
- Procfile, Makefile, package.json scripts
- README or docs with setup instructions
- .env / .env.example files
- Existing CLAUDE.md references to dev environment

If config files are found, extract: services, ports, start commands, database type, health checks, and log access methods (docker logs commands, log file paths, etc.). Then present what was discovered and ask the user to confirm or correct:

> "Based on the project config, here's what I found:
> - Services: [list]
> - Database: [type]
> - Start command: [command]
> - Health check: [endpoint]
>
> Is this correct? Anything missing or wrong?"

If nothing is found, ask the user directly:
> "No infrastructure config detected. To generate the environment playbook, I need to know:
> 1. How do you start the app? (e.g., `npm run dev`, `docker compose up`, manual process)
> 2. What URL does it run on?
> 3. Does it use a database? If so, what kind and how to access it?
> 4. Any other services it depends on?"

Combine discovered info + user corrections to write `e2e/env-playbook.md`:

```markdown
# Environment Playbook

## Architecture

- **Services:** [list with ports]
- **Database:** [type, access method]
- **Start command:** [how to bring everything up]
- **Health check:** [how to verify readiness]

## Data Access

Methods available for test data setup:

- **API route definitions:** [path to route files, e.g., `src/routes/` or `config/routes.rb` — always read these at runtime to find current endpoints]
- **API docs:** [path or URL if exists, otherwise omit this line]
- **Database CLI:** [e.g., docker exec container-name psql -U postgres]
- **Seed scripts:** [if any exist, otherwise omit this line]

Note: Do not hardcode specific API endpoints here — they change. The route definition files are the source of truth. Read them at runtime when you need to call an API for data setup.

## Logging

How to access service logs for debugging:

- **[service name]:** `[command, e.g., docker logs clawport-gateway --tail 100 --since 1m]`
- **[service name]:** `[command]`
- **Log files:** [if any services write to files instead of stdout, list paths]

## Startup Checklist

1. Start services: `[command]`
2. Wait for health: `[command with timeout]`
3. Verify database: `[command]`

## Known Issues

(Added automatically as eval runs encounter and solve environment problems)
```

Ask the user to review — the playbook is generated from config files, so confirm it looks right.

### Step 4: Verify the environment (smoke test)

After writing the playbook, actually run the Startup Checklist to confirm the environment works:

1. Execute each checklist step (start services, health checks, database connectivity)
2. Report results inline:
   - `✓ Services running`
   - `✓ Health check passed`
   - `✗ Database unreachable — [error]`
3. **If something fails, fix it right now** — don't just record the problem:
   - Services not running → start them
   - Containers outdated (missing migrations, new services) → rebuild using the playbook's build command
   - Dependencies missing → install them
   - Database needs migration → run migrations
4. After fixing, re-run the failed check to confirm
5. Only add to Known Issues if the fix requires **user-specific action** that can't be automated (e.g., "set up API key in .env", "install Docker")
6. Update the playbook with any corrections learned (wrong port, different command, etc.)

The goal is: when setup finishes, the environment is **actually ready to use**, not just documented. Only stop and report to the user when you genuinely can't fix the problem yourself.

### Step 5: Verify and report

- Confirm all files were created by listing them
- Print a quick-start guide:

```
E2E eval system ready.

Write specs:    /eval write <url>
Run a spec:     /eval e2e/specs/your-spec.md
Re-run setup:   /eval setup
Env playbook:   e2e/env-playbook.md
```

## Success Criteria

- `e2e/specs/` and `e2e/evidence/` directories exist
- `e2e/.gitignore` contains `evidence/`
- `e2e/env-playbook.md` exists with architecture, data access methods, and startup checklist
- Environment smoke test passed (or issues documented in playbook)
