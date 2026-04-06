---
description: Clean up local branches and worktrees, keeping only main branch and branches with active PRs (also cleans remote branches and updates remaining branches to latest)
---

Execute the following cleanup workflow:

## Step 1: Fetch Latest Remote State

Run `git fetch --all --prune` to:
- Get latest commits from all remotes
- Remove stale remote-tracking references

## Step 2: Identify Active PR Branches

Run `gh pr list --state open --json headRefName` to get all branches with active PRs.

## Step 3: List Current State

Show the user:
1. All local branches (`git branch`)
2. All worktrees (`git worktree list`)
3. Which branches have active PRs

## Step 4: Identify Branches to Delete

A branch should be KEPT if:
- It's the main branch (main, master, or the default branch)
- It's the currently checked out branch
- It has an active (open) PR

All other branches are candidates for deletion.

## Step 5: Clean Up Worktrees First

For each worktree that is not the main worktree:
- Check if its branch should be deleted
- If yes, remove the worktree with `git worktree remove --force <path>`

## Step 6: Prune Worktree References

Run `git worktree prune` to clean up stale worktree references.

## Step 7: Delete Local Branches

For each branch to delete:
- Use `git branch -D <branch>` to force delete (skip merge check)

## Step 8: Delete Remote Branches

For each branch that was deleted locally:
- Check if a corresponding remote branch exists with `git ls-remote --heads origin <branch>`
- If it exists, delete with `git push origin --delete <branch>`
- If deletion fails (e.g., protected branch), report the error but continue with other branches

## Step 9: Update Remaining Local Branches

First, get a map of all worktrees and their checked-out branches using `git worktree list --porcelain`.

For each local branch that was kept:
- Check if the branch has a corresponding remote tracking branch
- If yes, check if it's behind the remote with `git rev-list --count <branch>..origin/<branch>`
- If behind, determine how to update based on checkout status:

  **If the branch is checked out in the current worktree:**
  - Run `git pull --ff-only`
  - If fast-forward fails, report that manual intervention is needed

  **If the branch is checked out in another worktree:**
  - Run `git -C <worktree-path> pull --ff-only` to update it in that worktree
  - If fast-forward fails, report that manual intervention is needed

  **If the branch is not checked out in any worktree:**
  - Update with `git fetch origin <branch>:<branch>` (fast-forward only)
  - If the fast-forward fails (diverged), report it but don't force update

## Step 10: Summary

Report what was cleaned up:
- Number of worktrees removed
- Number of local branches deleted
- Number of remote branches deleted
- Number of local branches updated
- Any branches that failed to delete (with reasons)
- Any branches that failed to update (with reasons, e.g., diverged)
- What remains

## Important Notes

- Never delete the main/master branch (locally or remotely)
- If in a worktree, be careful not to delete the current worktree
- Remote branch deletion requires push access to the repository
- Protected branches on remote cannot be deleted via git push
