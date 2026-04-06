# Workflow: Tweak

Adjust the e2e skill system behavior based on a natural-language description.

## Process

1. Read all workflow files in `~/.claude/skills/e2e/workflows/` and `~/.claude/skills/e2e/SKILL.md` to understand the current system
2. Based on the user's description, identify which file(s) need to change
3. Present the planned change to the user:
   > "I'll update `[file]`: [what will change]. OK?"
4. If confirmed, make the edit
5. Show a before/after diff of the change

## Examples

- "run 的时候不要自动重启服务" → edit run-spec.md, change the worktree mismatch section
- "fix 的时候不写测试" → edit fix-spec.md, remove the TDD step
- "setup 的时候别问那么多直接干" → edit setup-project.md, reduce confirmation prompts
- "write 应该也检查现有的 playbook" → edit write-spec.md, add playbook reading step

## Rules

- Always show the change before applying
- Make minimal edits — don't rewrite whole files
- If the change affects multiple workflows, list all of them and confirm once
- After editing, read back the changed section to verify it reads correctly
