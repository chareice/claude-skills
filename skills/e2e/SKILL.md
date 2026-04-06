---
name: e2e
description: "E2E testing system: run, fix, write, list, suggest, set up, or tear down. Usage: /e2e <spec> | /e2e fix <spec> | /e2e write <desc> | /e2e list | /e2e suggest | /e2e setup | /e2e down"
argument-hint: <spec> | fix <spec> | write <desc> | list | suggest | setup [what changed] | down
---

Route `$ARGUMENTS` to the correct workflow:

| Argument pattern | Workflow | Example |
|---|---|---|
| Starts with `dev` | `workflows/dev.md` (pass the rest as feature description) | `/e2e dev 邮箱登录功能` |
| Path ending in `.md` | `workflows/run-spec.md` (auto-fix mode, default) | `/e2e e2e/specs/admin.md` |
| Starts with `report` | `workflows/run-spec.md` (report-only mode: don't fix, only report) | `/e2e report e2e/specs/admin.md` |
| Starts with `fix` | `workflows/fix-spec.md` (pass the spec path) | `/e2e fix e2e/specs/admin.md` |
| Starts with `write` | `workflows/write-spec.md` (pass the rest as the URL or description) | `/e2e write 管理员登录并查看用户列表` |
| `list` | `workflows/list-specs.md` | `/e2e list` |
| `suggest` | `workflows/suggest-specs.md` | `/e2e suggest` |
| Starts with `setup` | `workflows/setup-project.md` (pass the rest as description or PR number) | `/e2e setup` or `/e2e setup 换了LLM` or `/e2e setup #42` |
| `down` | `workflows/teardown.md` | `/e2e down` |
| Starts with `tweak` | `workflows/tweak.md` (pass the rest as change description) | `/e2e tweak fix的时候不写测试` |
| Empty | Ask what to do (run/write/list/setup) | `/e2e` |

Read the matched workflow file and follow it exactly. Pass the relevant portion of `$ARGUMENTS` as context to the workflow.

**Worktree resolution:** Before executing any workflow, determine the project root:

1. If the current directory contains `e2e/specs/`, use current directory
2. If not, check if this is a git worktree project by looking for a `.bare` directory in the parent:
   - Look for `../. bare` or `../../.bare` (the worktree root)
   - If found, the `main` sibling directory is the default: `<worktree-root>/main/`
3. Otherwise, search upward for `e2e/specs/`

All file paths (specs, playbook, evidence) are relative to the resolved project root. When starting services, use the resolved root as the working directory.

**Browser session isolation:** Every `agent-browser` command must include `--session <project-name>` to prevent different projects from sharing the same browser session. Derive the session name from the project directory name (e.g., `clawport`, `z1`). This applies to all workflows that use agent-browser (run, write, fix, dev).
