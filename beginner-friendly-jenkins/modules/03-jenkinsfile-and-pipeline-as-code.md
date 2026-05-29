# Module 03: Jenkinsfile (Kid Mode)

## What is Jenkinsfile
A recipe file for Jenkins.
It says exactly what to do.

## Typical stages
- Checkout
- Build
- Test
- Package
- Deploy

## Build tools in Jenkins
Most common build tools:
- Maven (Java projects)
- Gradle (Java/Kotlin projects)

Simple pipeline build steps:
- Maven build command: mvn clean test
- Gradle build command: ./gradlew clean test

## Good habits
- use timeout
- use retry for network actions
- clean workspace after run

## Practice
Write a 3-stage Jenkinsfile:
Build, Test, Package.
Make it run green.

## Copy-Paste Commands
Create a beginner Jenkinsfile quickly.

```bash
cd ~/jenkins-guide
mkdir -p pipeline-practice
cat > pipeline-practice/Jenkinsfile << 'EOF'
pipeline {
	agent any
	options { timeout(time: 10, unit: 'MINUTES') }
	stages {
		stage('Build') { steps { sh 'echo build step' } }
		stage('Test') { steps { sh 'echo test step' } }
		stage('Package') { steps { sh 'echo package step' } }
	}
	post { always { echo 'pipeline done' } }
}
EOF
cat pipeline-practice/Jenkinsfile
```

```powershell
cd e:/jenkins-guide
New-Item -ItemType Directory -Path ./pipeline-practice -Force
Set-Content -Path ./pipeline-practice/Jenkinsfile -Value @'
pipeline {
	agent any
	options { timeout(time: 10, unit: 'MINUTES') }
	stages {
		stage('Build') { steps { echo 'build step' } }
		stage('Test') { steps { echo 'test step' } }
		stage('Package') { steps { echo 'package step' } }
	}
	post { always { echo 'pipeline done' } }
}
'@
Get-Content ./pipeline-practice/Jenkinsfile
```

Maven/Gradle examples for Jenkins stage:

```groovy
stage('Build Maven') {
	steps { sh 'mvn clean test' }
}

stage('Build Gradle') {
	steps { sh './gradlew clean test' }
}
```
