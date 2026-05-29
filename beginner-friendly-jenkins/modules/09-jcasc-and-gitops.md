# Module 09: JCasC and GitOps (Kid Mode)

## What is JCasC
Jenkins settings written in yaml files.
So config is also code.

## Why good
- easy to track changes
- easy to review in pull request
- easy to rollback

## Safe change flow
1. create branch
2. edit yaml
3. open PR
4. merge
5. reload config
6. verify Jenkins

## Practice
Change one small setting using JCasC and rollback once.

## Copy-Paste Commands
Use these commands for a basic JCasC git workflow.

```bash
cd ~/jenkins-guide
git checkout -b jcasc-change-demo
sed -i 's/Jenkins configured/Jenkins configured by GitOps/' casc_configs/jenkins.yaml
git add casc_configs/jenkins.yaml
git commit -m "demo: update Jenkins message via JCasC"
git log --oneline -n 3
```

```powershell
cd e:/jenkins-guide
git checkout -b jcasc-change-demo
(Get-Content ./casc_configs/jenkins.yaml) -replace 'Jenkins configured','Jenkins configured by GitOps' | Set-Content ./casc_configs/jenkins.yaml
git add ./casc_configs/jenkins.yaml
git commit -m "demo: update Jenkins message via JCasC"
git log --oneline -n 3
```

Rollback demo:

```bash
git revert --no-edit HEAD
git log --oneline -n 3
```
