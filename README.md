# chareice-skills

Claude Code skills by chareice for DevOps, testing, and productivity.

## Installation

```bash
/plugin marketplace add chareice/claude-skills
/plugin enable chareice-skills
/reload-plugins
```

## Skills

### devops

Manage deployments and diagnose production services.

```
/devops              # Deploy (default)
/devops status       # Check service status
/devops logs api     # View service logs
/devops rollback     # Rollback deployment
/devops health       # Health check
/devops diagnose     # Diagnose production issues
/devops setup        # Set up environment
/devops connect      # Connect to server
```

### e2e

E2E testing system with spec-driven workflows.

```
/e2e <spec.md>             # Run a spec (auto-fix on failure)
/e2e fix <spec.md>         # Fix a failing spec
/e2e write <description>   # Write a new spec from description
/e2e list                  # List all specs
/e2e suggest               # Suggest specs based on codebase
/e2e setup                 # Set up E2E environment
/e2e down                  # Tear down environment
/e2e dev <feature>         # Dev mode for a feature
```

### openapi-generator

Generate and sync OpenAPI 3.0.3 (REST) and AsyncAPI 3.0.0 (WebSocket) documentation by scanning project source code. Currently supports Rust web frameworks (Axum, Actix-web, Rocket, Poem).

- **Generate mode**: Scan routes, extract request/response types, produce split-file specs
- **Sync mode**: Diff existing specs against current code and update

## Slash Commands

### /ch-memory-analysis

Investigate memory usage in the ClickHouse `events` database. Runs a series of diagnostic queries covering:

- Overall table sizes (disk, uncompressed, primary key memory)
- Memory allocation by component (caches, buffers)
- Running queries memory consumption
- Dictionary memory usage (geoip, blacklist, etc.)
- Column-level compression analysis
- MergeTree parts status

Requires ClickHouse MCP server.

### /ch-slow-query-analysis

Analyze slow and resource-intensive queries in ClickHouse over the last 24 hours:

- Slowest queries (by duration, memory, CPU)
- Recurring slow query patterns
- Partition pruning effectiveness
- Index usage analysis
- EXPLAIN plans for problematic queries
- Optimization recommendations (indexes, PREWHERE, materialized views, schema changes)

Requires ClickHouse MCP server.

### /cleanup-branches

Clean up local git branches and worktrees. Keeps main branch and branches with active PRs, deletes the rest:

- Removes stale worktrees
- Deletes local and remote branches
- Updates remaining branches to latest remote
- Supports worktree-based project structure

## License

MIT
