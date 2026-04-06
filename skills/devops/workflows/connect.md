# Connect to Existing Environment

The user already has a running deployment. Inspect it and generate the runbook.

1. **Gather connection info** — ask for: SSH address, which user, which directory the app lives in
2. **Inspect the server** via SSH:
   ```bash
   # OS and resources
   cat /etc/os-release | head -3 && free -h && df -h /

   # Running containers
   docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

   # Find compose files and env files
   find <app-dir> -name "*.yaml" -o -name "*.yml" | grep -i compose
   find <app-dir> -name "*.env" -not -path "*/node_modules/*"

   # Reverse proxy config
   cat /etc/caddy/Caddyfile 2>/dev/null || nginx -T 2>/dev/null | head -50

   # Deploy scripts
   find <app-dir> -name "deploy*" -type f

   # Systemd services
   systemctl list-units --type=service --state=running | grep -i -E "docker|compose|caddy|nginx|webhook"
   ```
3. **Inspect the repo** locally:
   ```bash
   # Compose files
   find infra/ -name "*.yaml" -o -name "*.yml" | head -20

   # CI/CD workflows
   ls .github/workflows/

   # Dockerfiles
   find . -name "Dockerfile*" -not -path "*/node_modules/*"

   # Env templates
   find . -name "*.env.example" -not -path "*/node_modules/*"
   ```
4. **Cross-reference** server state with repo config — identify which compose file is in use, which images are custom-built vs pulled from registries
5. **Generate `docs/deployment/runbook.md`** following the runbook template below
6. **Show the runbook to the user** for review before committing

## Runbook Template

```markdown
# Deployment Runbook

Operational reference for deploying and managing <project>.
Keep this document up to date when infrastructure changes.

## Environments

| Environment | Host | SSH | Domains | Health URL |
|-------------|------|-----|---------|------------|
| <env-name> | <ip> | `ssh <user>@<ip>` | <domains> | <health-url> |

## <Environment Name>

### Server
<OS, resources>

### Services
<table of services, images, ports, notes>

### Paths
<directory layout on server>

### Reverse Proxy
<config location and routing rules>

### Deploy Methods
<how to deploy: auto, manual, compose commands>

### Common Operations
<status, logs, health, restart, rollback commands>

## CI/CD Workflows
<what triggers builds, what gets built>

## Notes
<gotchas, inactive features, things to watch out for>
```
