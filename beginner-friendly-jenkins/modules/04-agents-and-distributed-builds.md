# Module 04: Agents and Distributed Builds (Kid Mode)

## Why agents
One machine can become tired.
Multiple agents share work and become faster.

## Labels
Give agents names like:
- linux
- docker
- deploy

Then choose correct agent per stage.

## Common problem
Works on agent A, fails on B.
Reason: tools or versions are different.
Fix: standardize environment.

## Practice
Run build on one label and test on another label.

## Copy-Paste Commands
Use these commands to prepare an agent practice note and example stage labels.

```bash
cd ~/jenkins-guide
mkdir -p agent-practice
cat > agent-practice/Jenkinsfile << 'EOF'
pipeline {
	agent none
	stages {
		stage('Build on linux') {
			agent { label 'linux' }
			steps { sh 'echo build on linux agent' }
		}
		stage('Test on docker') {
			agent { label 'docker' }
			steps { sh 'echo test on docker agent' }
		}
	}
}
EOF
cat agent-practice/Jenkinsfile
```

```powershell
cd e:/jenkins-guide
New-Item -ItemType Directory -Path ./agent-practice -Force
Set-Content -Path ./agent-practice/Jenkinsfile -Value @'
pipeline {
	agent none
	stages {
		stage('Build on linux') {
			agent { label 'linux' }
			steps { echo 'build on linux agent' }
		}
		stage('Test on docker') {
			agent { label 'docker' }
			steps { echo 'test on docker agent' }
		}
	}
}
'@
Get-Content ./agent-practice/Jenkinsfile
```
