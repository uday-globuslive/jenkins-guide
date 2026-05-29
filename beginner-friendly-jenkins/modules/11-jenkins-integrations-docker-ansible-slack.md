# Module 11: Jenkins Integrations (Docker, Ansible, Slack) (Kid Mode)

## Why integrations matter
Jenkins is the manager.
Other tools are helpers.
Together they do real project work.

## 1. Jenkins + Docker
Use Docker to build and run app images.

Simple pipeline step idea:
- build image
- tag image
- push image to registry

Example stage:

```groovy
stage('Docker Build') {
  steps {
    sh 'docker build -t myapp:demo .'
  }
}
```

## 2. Jenkins + Ansible
Use Ansible to configure servers and deploy apps.

Simple pipeline step idea:
- run ansible playbook
- deploy app files/service

Example stage:

```groovy
stage('Deploy with Ansible') {
  steps {
    sh 'ansible-playbook -i inventory.ini deploy.yml'
  }
}
```

## 3. Jenkins + Slack
Use Slack for team notifications.

Notify on:
- success
- failure
- deployment complete

Example post block:

```groovy
post {
  success {
    slackSend channel: '#ci-alerts', message: 'Build passed'
  }
  failure {
    slackSend channel: '#ci-alerts', message: 'Build failed'
  }
}
```

## Copy-Paste Commands

```bash
cd ~/jenkins-guide
mkdir -p integration-practice
cat > integration-practice/Jenkinsfile << 'EOF'
pipeline {
  agent any
  stages {
    stage('Docker Build') {
      steps { sh 'echo docker build -t myapp:demo .' }
    }
    stage('Ansible Deploy') {
      steps { sh 'echo ansible-playbook -i inventory.ini deploy.yml' }
    }
  }
  post {
    success { echo 'slack success notification here' }
    failure { echo 'slack failure notification here' }
  }
}
EOF
cat integration-practice/Jenkinsfile
```

```powershell
cd e:/jenkins-guide
New-Item -ItemType Directory -Path ./integration-practice -Force
Set-Content -Path ./integration-practice/Jenkinsfile -Value @'
pipeline {
  agent any
  stages {
    stage('Docker Build') {
      steps { echo 'docker build -t myapp:demo .' }
    }
    stage('Ansible Deploy') {
      steps { echo 'ansible-playbook -i inventory.ini deploy.yml' }
    }
  }
  post {
    success { echo 'slack success notification here' }
    failure { echo 'slack failure notification here' }
  }
}
'@
Get-Content ./integration-practice/Jenkinsfile
```

## Practice
1. Add Docker build stage.
2. Add Ansible deploy stage.
3. Add Slack-style success/failure message.
4. Run and verify pipeline flow.
