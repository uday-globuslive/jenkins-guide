# Module 07: Scale, Reliability, and Operations (Kid Mode)

## Story
You run one ice cream cart. Easy.
Now you run 100 carts. Hard.
Jenkins at scale is like that.

## What "scale" means
More developers, more jobs, more builds, more agents.

## Keep Jenkins healthy
- controller should plan, not do heavy builds
- heavy work runs on agents
- monitor queue time and failures

## Backup and restore
Always keep backups.
Practice restore, not just backup.
If controller crashes, you must recover quickly.

## Reliability checklist
- backups daily
- restore drill weekly or monthly
- plugin updates in controlled window
- alert when queue grows too much

## Practice
Write your recovery plan:
- where backups are stored
- how to restore
- target recovery time

## Copy-Paste Commands
Use these commands to inspect Jenkins health and create backup files.

```bash
cd ~/jenkins-guide
docker-compose ps
docker stats --no-stream
mkdir -p backups
docker run --rm --volumes-from jenkins -v $(pwd)/backups:/backup ubuntu tar czf /backup/jenkins_home_backup.tar.gz /var/jenkins_home
ls -lh backups
```

```powershell
cd e:/jenkins-guide
docker compose ps
docker stats --no-stream
New-Item -ItemType Directory -Path ./backups -Force
docker run --rm --volumes-from jenkins -v ${PWD}/backups:/backup ubuntu tar czf /backup/jenkins_home_backup.tar.gz /var/jenkins_home
Get-ChildItem ./backups
```
