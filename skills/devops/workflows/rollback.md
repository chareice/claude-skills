# Rollback

1. Identify the target version (commit SHA, tag, or image digest)
2. SSH to server, pull the specific tagged images
3. Restart with compose
4. Verify health

## Post-Rollback Verification

1. Run health check
2. Check container status (all should be "healthy" or "Up")
3. Tail api logs briefly to confirm no crash loops
4. Report result to user
