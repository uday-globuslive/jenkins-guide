# Module 08: Troubleshooting and Incidents (Kid Mode)

## Easy debug method
1. find first red stage
2. read exact error line
3. check recent change
4. fix and rerun

## Common failures
- wrong command
- missing dependency
- expired token
- offline agent

## Incident basics
- share status quickly
- fix impact first
- write postmortem later

## Practice
Take one failed build and write:
- root cause
- quick fix
- long-term prevention

## Copy-Paste Commands
Use these commands when a build fails.

```bash
cd ~/jenkins-guide
docker-compose ps
docker-compose logs --tail=200 jenkins
docker-compose logs -f jenkins
```

```powershell
cd e:/jenkins-guide
docker compose ps
docker compose logs --tail=200 jenkins
docker compose logs -f jenkins
```

In Jenkins UI:
1. Open failed build
2. Click Console Output
3. Find the first ERROR line
