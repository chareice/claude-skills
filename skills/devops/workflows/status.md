# Status

Show current state for the target environment:

1. **Container status** via SSH:
   ```bash
   docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
   ```
2. **Latest CI/CD deploy run status** (if applicable)
3. **Health check** — hit the environment's health endpoint and report
