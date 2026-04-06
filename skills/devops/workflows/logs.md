# Logs

View recent container logs via SSH.

1. Accept optional service name from args (default: the main service, usually `api`)
2. SSH to the target environment
3. Run:
   ```bash
   docker logs --tail 100 -f <container-name>
   ```
4. If the user describes a specific issue, grep for relevant patterns:
   ```bash
   docker logs --tail 500 <container-name> 2>&1 | grep -i -E "error|exception|fatal|panic"
   ```
