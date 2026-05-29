# Module 00: CI/CD and Jenkins Foundations (Kid Mode)

## Story
You made a toy car.
Before giving it to a friend, you should:
- check wheels
- test battery
- pack safely

Software needs same care.

## Simple meanings
- CI: check every change quickly
- CD: deliver safely after checks
- Jenkins: robot that does checks and delivery steps

## Why teams use Jenkins
- fewer mistakes
- faster feedback
- same process every time

## Tiny exercise
Write your own 5-step app release checklist on paper.

## Copy-Paste Commands
Use these commands to make your first CI/CD practice notes.

```powershell
cd e:/jenkins-guide
New-Item -ItemType Directory -Path ./my-jenkins-notes -Force
Set-Content -Path ./my-jenkins-notes/release-checklist.txt -Value @'
1. get code
2. build app
3. run tests
4. package app
5. deploy app
'@
Get-Content ./my-jenkins-notes/release-checklist.txt
```

```bash
cd ~/jenkins-guide
mkdir -p my-jenkins-notes
cat > my-jenkins-notes/release-checklist.txt << 'EOF'
1. get code
2. build app
3. run tests
4. package app
5. deploy app
EOF
cat my-jenkins-notes/release-checklist.txt
```
