# Module 02: Jenkins UI and Jobs (Kid Mode)

## UI places
- Dashboard: all jobs
- New Item: create job
- Console Output: read errors
- Manage Jenkins: global settings

## Job types
- Freestyle: quick and simple
- Pipeline: better for real teams
- Multibranch: auto for branches and PRs

## Freestyle project (how to create)
1. New Item
2. Type a name
3. Choose Freestyle project
4. Add build step (for example shell command)
5. Save and Build Now

Use Freestyle for quick learning.
Use Pipeline for real long-term team work.

## Build history (what to read)
Build History helps you see:
- latest success/failure
- how long builds take
- when failures started

Beginner habit:
- compare last green build and first red build.

## Build flow
1. Trigger
2. Queue
3. Run on agent
4. Show result

## Build triggers you must know
- SCM polling: Jenkins checks repo every few minutes.
- Webhook: GitHub/GitLab pushes event to Jenkins instantly.
- Scheduled trigger: run by clock (cron style).

Simple examples:
- SCM polling: H/5 * * * *
- Scheduled nightly build: 0 2 * * *

## GitHub/GitLab automatic trigger (simple setup)
1. In Jenkins job, enable webhook trigger.
2. Copy Jenkins webhook URL.
3. In GitHub/GitLab repo settings, add webhook.
4. Choose push events.
5. Push new commit and verify Jenkins starts automatically.

## Practice
Create one pipeline with Build and Test stage.
Then break one command and fix it.

## Copy-Paste Commands
Use this sample repository to practice UI build flow.

```bash
cd ~/jenkins-guide
git init demo-job
cd demo-job
cat > Jenkinsfile << 'EOF'
pipeline {
	agent any
	stages {
		stage('Build') {
			steps { sh 'echo Build OK' }
		}
		stage('Test') {
			steps { sh 'echo Test OK' }
		}
	}
}
EOF
git add .
git commit -m "add demo Jenkinsfile"
```

```powershell
cd e:/jenkins-guide
New-Item -ItemType Directory -Path ./demo-job -Force
Set-Content -Path ./demo-job/Jenkinsfile -Value @'
pipeline {
	agent any
	stages {
		stage('Build') { steps { echo 'Build OK' } }
		stage('Test') { steps { echo 'Test OK' } }
	}
}
'@
Get-Content ./demo-job/Jenkinsfile
```

Webhook and schedule helper commands:

```bash
# Poll every 5 minutes (job configuration value)
H/5 * * * *

# Nightly at 2 AM (job configuration value)
0 2 * * *
```
