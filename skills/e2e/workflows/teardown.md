# Workflow: Teardown

Stop the test environment and clean up test artifacts.

## Process

1. Read `e2e/env-playbook.md` to find the start command and derive the corresponding stop command
2. Stop the services
3. Optionally clean up test data (ask the user):
   > "Services stopped. Also clean up test data (database reset, clear evidence screenshots)?"
   - If yes: reset database if playbook documents how, clear `e2e/evidence/`
   - If no: just stop services
4. Report what was done
