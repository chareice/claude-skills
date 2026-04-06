# Deploy

1. Check if there are unpushed commits on the deploy branch — if so, push first
2. Confirm with user what's being deployed (show recent commits since last deploy)
3. Look up the target environment's deploy method in the runbook and execute it
4. Monitor: watch for health check to pass
5. Report result

## Post-Deploy Verification

After deploy completes:
1. Run health check
2. Check container status (all should be "healthy" or "Up")
3. Tail api logs briefly to confirm no crash loops
4. Report result to user
