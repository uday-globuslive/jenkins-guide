# Module 10: Advanced Pipeline Patterns (Kid Mode)

## Real team patterns
- PR pipeline: fast checks
- main pipeline: full checks
- release pipeline: careful deploy and approvals

## Helpful ideas
- parallel tests for speed
- shared library for reusable steps
- policy gates for quality and security

## Advanced pipeline building blocks
- Parallel stages: run many checks at same time.
- Conditional builds: run stage only for specific branch/rule.
- Build pipelines: connect jobs in sequence (build -> test -> deploy).

## Practice
Create branch-based logic:
- PR: lint + unit tests
- main: full test + package
- release: deploy with approval

## Copy-Paste Commands
Create a branch-aware Jenkinsfile.

```bash
cd ~/jenkins-guide
mkdir -p advanced-pipeline-practice
cat > advanced-pipeline-practice/Jenkinsfile << 'EOF'
pipeline {
	agent any
	stages {
		stage('PR Checks') {
			when { expression { env.BRANCH_NAME?.startsWith('PR-') } }
			steps { sh 'echo lint and unit tests' }
		}
		stage('Main Checks') {
			when { branch 'main' }
			steps { sh 'echo full tests and package' }
		}
		stage('Release Deploy') {
			when { branch 'release' }
			steps {
				input 'Deploy to production?'
				sh 'echo deploy release'
			}
		}
	}
}
EOF
cat advanced-pipeline-practice/Jenkinsfile
```

```powershell
cd e:/jenkins-guide
New-Item -ItemType Directory -Path ./advanced-pipeline-practice -Force
Set-Content -Path ./advanced-pipeline-practice/Jenkinsfile -Value @'
pipeline {
	agent any
	stages {
		stage('PR Checks') {
			when { expression { env.BRANCH_NAME?.startsWith('PR-') } }
			steps { echo 'lint and unit tests' }
		}
		stage('Main Checks') {
			when { branch 'main' }
			steps { echo 'full tests and package' }
		}
		stage('Release Deploy') {
			when { branch 'release' }
			steps {
				input 'Deploy to production?'
				echo 'deploy release'
			}
		}
	}
}
'@
Get-Content ./advanced-pipeline-practice/Jenkinsfile
```

Parallel stage example:

```groovy
stage('Parallel Checks') {
	parallel {
		stage('Lint') { steps { sh 'echo lint' } }
		stage('Unit Test') { steps { sh 'echo unit test' } }
	}
}
```
