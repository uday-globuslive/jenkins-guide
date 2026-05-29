# Module 06: Quality, Artifacts, Releases (Kid Mode)

## Quality gate
A gate is stop/go.
If tests fail: stop.
If security is bad: stop.

## Artifact
Artifact is final package from build.
Build once, deploy same package everywhere.

## Safe release path
- deploy to staging
- run checks
- approve production
- monitor health

## Practice
Fail a test and verify deploy stage does not run.

## Copy-Paste Commands
Create a mini pipeline with a quality gate.

```bash
cd ~/jenkins-guide
mkdir -p release-practice
cat > release-practice/Jenkinsfile << 'EOF'
pipeline {
	agent any
	stages {
		stage('Test') {
			steps { sh 'exit 1' }
		}
		stage('Deploy') {
			steps { sh 'echo should not run when tests fail' }
		}
	}
}
EOF
cat release-practice/Jenkinsfile
```

```powershell
cd e:/jenkins-guide
New-Item -ItemType Directory -Path ./release-practice -Force
Set-Content -Path ./release-practice/Jenkinsfile -Value @'
pipeline {
	agent any
	stages {
		stage('Test') { steps { error 'test failed on purpose' } }
		stage('Deploy') { steps { echo 'should not run when tests fail' } }
	}
}
'@
Get-Content ./release-practice/Jenkinsfile
```
