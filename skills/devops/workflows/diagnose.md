# Diagnose

Systematically investigate production issues. Take the user's symptom description as starting context.

## Step 1: Quick Triage

SSH to the target environment and run a quick health snapshot:

```bash
# Health endpoint
curl -s -o /dev/null -w "%{http_code}" <health-url>

# Container status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Resource usage
free -h && df -h / && uptime

# Recent container restarts
docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -i -E "restart|exited"
```

Report the triage results to the user before going deeper.

## Step 2: Layered Investigation

Based on triage results and the reported symptom, investigate the relevant layer(s). Work top-down — eliminate infrastructure issues before diving into application logic.

### Infrastructure Layer

When: high CPU/memory/disk, network timeouts, DNS issues

```bash
# CPU and memory per process
top -bn1 | head -20

# Disk usage detail
du -sh /var/lib/docker/* 2>/dev/null | sort -rh | head -10

# Network connectivity
ping -c 3 <external-dependency> 2>&1
curl -s -m 5 <dependency-health-url>

# Docker disk usage
docker system df
```

### Service Layer

When: containers crashing, restart loops, port conflicts, image pull failures

```bash
# Container details including restart count
docker inspect --format '{{.Name}} restarts={{.RestartCount}} state={{.State.Status}}' $(docker ps -aq)

# Recent events
docker events --since 30m --until 0s 2>/dev/null | tail -20

# Compose status
cd <app-dir> && docker compose ps
```

### Application Layer

When: HTTP errors, slow responses, application exceptions

```bash
# Recent error logs (last 200 lines, errors only)
docker logs --tail 200 <container> 2>&1 | grep -i -E "error|exception|fatal|panic|traceback"

# Full recent logs
docker logs --tail 100 --timestamps <container> 2>&1

# If the app exposes metrics
curl -s http://localhost:<metrics-port>/metrics 2>/dev/null | head -30
```

### Data Layer

When: database connection issues, query timeouts, data corruption

```bash
# Database container health
docker exec <db-container> pg_isready 2>/dev/null || docker exec <db-container> mysqladmin ping 2>/dev/null

# Connection count
docker exec <db-container> psql -U <user> -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null

# Database disk usage
docker exec <db-container> psql -U <user> -c "SELECT pg_size_pretty(pg_database_size(current_database()));" 2>/dev/null
```

## Step 3: Report

After investigation, report to the user:

1. **What's wrong** — root cause or most likely cause
2. **Evidence** — the specific output that points to this conclusion
3. **Fix** — concrete next steps
4. **If fix requires a code change or deploy**, suggest using the deploy workflow

## Troubleshooting Quick Reference

| Symptom | First check |
|---|---|
| Health check fails | Container status + api logs |
| 502/503 errors | Reverse proxy config + upstream container status |
| Slow responses | CPU/memory + application logs for slow queries |
| Container restart loop | `docker logs <container>` for crash reason |
| Disk full | `df -h` + `docker system df` + prune old images |
| Can't connect to DB | DB container status + connection count + credentials |
| Auto-deploy not working | Deploy mechanism logs (watchtower/webhook) |
| SSH connection fails | Server may be down, or SSH key not loaded (check 1Password) |
