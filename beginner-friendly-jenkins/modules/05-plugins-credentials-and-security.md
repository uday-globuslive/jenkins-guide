# Module 05: Plugins, Credentials, Security (Kid Mode)

## Plugins
Plugins are extra powers.
Too many powers can break stability.
Install only what you need.

## Credentials
Never write password in code.
Store secrets in Jenkins Credentials.
Use them only when pipeline runs.

Use Jenkins Credentials plugin to manage secrets safely.

## Security basics
- no anonymous access
- strong passwords
- HTTPS
- least privilege roles

## Users, roles, and permissions (easy view)
- User: person account (for example dev1, admin1)
- Role: group of permissions (for example Viewer, Developer, Admin)
- Permission: exact action allowed (read, build, configure, administer)

Beginner safe setup:
- Viewer role: read only
- Developer role: read + build
- Admin role: full control

## Practice
Add one secret token in credentials and use it safely in pipeline.

## Copy-Paste Commands
Use these commands to create a safe secret file and a Jenkinsfile that reads it from environment.

```bash
cd ~/jenkins-guide
mkdir -p security-practice
cat > security-practice/Jenkinsfile << 'EOF'
pipeline {
	agent any
	stages {
		stage('Use Secret Safely') {
			steps {
				withCredentials([string(credentialsId: 'demo-token', variable: 'API_TOKEN')]) {
					sh 'echo Token length is ${#API_TOKEN}'
				}
			}
		}
	}
}
EOF
cat security-practice/Jenkinsfile
```

```powershell
cd e:/jenkins-guide
New-Item -ItemType Directory -Path ./security-practice -Force
Set-Content -Path ./security-practice/Jenkinsfile -Value @'
pipeline {
	agent any
	stages {
		stage('Use Secret Safely') {
			steps {
				withCredentials([string(credentialsId: 'demo-token', variable: 'API_TOKEN')]) {
					echo "Token loaded safely"
				}
			}
		}
	}
}
'@
Get-Content ./security-practice/Jenkinsfile
```

In Jenkins UI:
1. Manage Jenkins -> Credentials
2. Add Credentials -> Secret text
3. ID: demo-token
