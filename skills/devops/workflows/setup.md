# Set Up New Environment

The user wants to deploy to a fresh server.

1. **Gather info** — ask for: server IP/hostname, SSH user, target domain(s), desired directory layout
2. **Inspect the repo** to understand what needs to be deployed:
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
3. **Guide the setup** step by step:
   - Verify server prerequisites (Docker, Docker Compose, reverse proxy)
   - Create directory layout on server
   - Clone the repo (or set up image-only deployment)
   - Create env file from template — walk through each required variable
   - Start services with compose
   - Configure reverse proxy
   - Set up auto-deploy mechanism (Watchtower, webhook, or manual)
   - Run health checks to verify
4. **Generate `docs/deployment/runbook.md`** following the runbook template in `workflows/connect.md`
5. **Show the runbook to the user** for review before committing
