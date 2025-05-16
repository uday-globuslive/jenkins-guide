# Complete Jenkins Setup Guide with Configuration as Code

This guide provides detailed, step-by-step instructions for setting up a Jenkins CI/CD environment with Configuration as Code, including master node deployment on Azure and slave nodes across various environments (Azure, on-premise, VirtualBox).

## Table of Contents

- [Part 1: Install and Set Up Jenkins on Azure](#part-1-install-and-set-up-jenkins-on-azure)
- [Part 2: Set Up Configuration as Code](#part-2-set-up-configuration-as-code)
- [Part 3: Set Up Automated Configuration Updates](#part-3-set-up-automated-configuration-updates)
- [Part 4: Add More Advanced Configuration](#part-4-add-more-advanced-configuration)
- [Part 5: Setting Up VirtualBox Agent](#part-5-setting-up-virtualbox-agent)
- [Part 6: Configure Azure Slave Nodes](#part-6-configure-azure-slave-nodes)
- [Part 7: Create a Complete CI/CD Pipeline](#part-7-create-a-complete-cicd-pipeline)
- [Part 8: Docker-based Setup (Alternative Approach)](#part-8-docker-based-setup-alternative-approach)

## PART 1: Install and Set Up Jenkins on Azure

### Step 1: Create an Azure VM for Jenkins
1. Log into the Azure Portal (portal.azure.com)
2. Click "Create a resource"
3. Search for "Ubuntu Server" and select it
4. Click "Create"
5. Fill in basic details:
   - Subscription: Choose your subscription
   - Resource group: Create new "jenkins-rg"
   - VM name: "jenkins-master"
   - Region: Choose closest to you
   - Size: Standard D2s v3 (2 vcpus, 8 GiB memory)
   - Username: "jenkinsadmin"
   - Authentication type: SSH public key
   - Generate new key pair or use existing
6. Networking:
   - Allow SSH (port 22)
   - Add HTTP (port 8080) for Jenkins web interface
7. Click "Review + create" then "Create"

### Step 2: SSH into your VM

```bash
# Download the .pem file if you generated a new key
chmod 400 your-key.pem
ssh -i your-key.pem jenkinsadmin@YOUR_VM_IP_ADDRESS
```

### Step 3: Install Jenkins

```bash
# Update packages
sudo apt update

# Install Java
sudo apt install -y openjdk-11-jdk

# Add Jenkins repository key
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -

# Add Jenkins repository
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

# Update package list
sudo apt update

# Install Jenkins
sudo apt install -y jenkins

# Start Jenkins service
sudo systemctl start jenkins

# Enable Jenkins to start at boot
sudo systemctl enable jenkins

# Check Jenkins status
sudo systemctl status jenkins
```

### Step 4: Access Jenkins for the first time
1. Open your web browser and navigate to: `http://YOUR_VM_IP_ADDRESS:8080`
2. You'll be asked for an initial admin password. Get it from your VM:
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
3. Copy and paste this password into the browser
4. Choose "Install suggested plugins"
5. Create your first admin user when prompted:
   - Username: admin
   - Password: [choose a strong password]
   - Full name: Jenkins Admin
   - Email: your.email@example.com
6. Click "Save and Continue"
7. Keep the default Jenkins URL and click "Save and Finish"
8. Click "Start using Jenkins"

## PART 2: Set Up Configuration as Code

### Step 5: Install the Configuration as Code Plugin
1. In Jenkins dashboard, click "Manage Jenkins"
2. Click "Manage Plugins"
3. Click the "Available" tab
4. In the search box, type "Configuration as Code"
5. Check the box next to "Configuration as Code" plugin
6. Click "Install without restart"
7. Wait for the installation to complete

### Step 6: Create a GitHub Repository for Your Configuration
1. Log into GitHub (or create an account if you don't have one)
2. Click the "+" icon in the top right and select "New repository"
3. Name: "jenkins-config"
4. Description: "Jenkins Configuration as Code"
5. Make it Public
6. Click "Create repository"

### Step 7: Create Configuration Files Locally
1. On your local computer (not the VM), create a directory:
   ```bash
   mkdir jenkins-config
   cd jenkins-config
   ```

2. Initialize Git:
   ```bash
   git init
   ```

3. Create a configuration directory:
   ```bash
   mkdir -p casc_configs
   ```

4. Create a basic configuration file (casc_configs/jenkins.yaml):
   ```bash
   nano casc_configs/jenkins.yaml
   ```

5. Add this basic configuration:
   ```yaml
   jenkins:
     systemMessage: "Jenkins configured via Configuration as Code"
     numExecutors: 2
     
     securityRealm:
       local:
         allowsSignup: false
         users:
           - id: "${ADMIN_USER}"
             password: "${ADMIN_PASSWORD}"
   
   tool:
     git:
       installations:
         - name: git
           home: /usr/bin/git
   ```

6. Commit your changes:
   ```bash
   git add .
   git commit -m "Initial Jenkins configuration"
   ```

7. Connect to your GitHub repository:
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/jenkins-config.git
   git branch -M main
   git push -u origin main
   ```

### Step 8: Configure Jenkins to Use Your GitHub Repository
1. SSH back into your Jenkins VM:
   ```bash
   ssh -i your-key.pem jenkinsadmin@YOUR_VM_IP_ADDRESS
   ```

2. Create a directory for configuration:
   ```bash
   sudo mkdir -p /var/lib/jenkins/casc_configs
   sudo chown jenkins:jenkins /var/lib/jenkins/casc_configs
   ```

3. Edit Jenkins configuration:
   ```bash
   sudo nano /etc/default/jenkins
   ```

4. Add these environment variables:
   ```
   CASC_JENKINS_CONFIG=/var/lib/jenkins/casc_configs
   ADMIN_USER=admin
   ADMIN_PASSWORD=your_admin_password
   ```

5. Save and exit (Ctrl+X, then Y, then Enter)

6. Restart Jenkins:
   ```bash
   sudo systemctl restart jenkins
   ```

## PART 3: Set Up Automated Configuration Updates

### Step 9: Create a Jenkins Job to Monitor Your GitHub Repository
1. Back in the Jenkins web interface, click "New Item"
2. Enter item name: "UpdateJenkinsConfig"
3. Select "Pipeline" and click "OK"
4. In the configuration page:
   - Check "GitHub hook trigger for GITScm polling" under "Build Triggers"
   - Under "Pipeline", select "Pipeline script from SCM"
   - Select "Git" from the SCM dropdown
   - Repository URL: https://github.com/YOUR_USERNAME/jenkins-config.git
   - Branch Specifier: */main
   - Script Path: Jenkinsfile
5. Click "Save"

### Step 10: Add a Jenkinsfile to Your Repository
1. On your local computer, in your jenkins-config directory:
   ```bash
   nano Jenkinsfile
   ```

2. Add this pipeline script:
   ```groovy
   pipeline {
       agent any
       
       environment {
           JCASC_DIR = '/var/lib/jenkins/casc_configs'
       }
       
       stages {
           stage('Checkout') {
               steps {
                   checkout scm
               }
           }
           
           stage('Backup Existing Config') {
               steps {
                   sh '''
                   mkdir -p ${JCASC_DIR}/backups
                   if [ -f ${JCASC_DIR}/jenkins.yaml ]; then
                       cp ${JCASC_DIR}/jenkins.yaml ${JCASC_DIR}/backups/jenkins-$(date +%Y%m%d-%H%M%S).yaml
                   fi
                   '''
               }
           }
           
           stage('Update Configuration') {
               steps {
                   sh '''
                   cp casc_configs/jenkins.yaml ${JCASC_DIR}/jenkins.yaml
                   '''
               }
           }
           
           stage('Apply Configuration') {
               steps {
                   sh '''
                   curl -X POST http://localhost:8080/reload-configuration-as-code/
                   '''
               }
           }
       }
   }
   ```

3. Commit and push:
   ```bash
   git add Jenkinsfile
   git commit -m "Add configuration update pipeline"
   git push
   ```

### Step 11: Set Up GitHub Webhook
1. In your GitHub repository, click "Settings"
2. Click "Webhooks" in the left sidebar
3. Click "Add webhook"
4. Fill in:
   - Payload URL: http://YOUR_VM_IP_ADDRESS:8080/github-webhook/
   - Content type: application/json
   - Secret: leave blank for now (in production, use a secret token)
   - Select "Just the push event"
5. Click "Add webhook"

### Step 12: Install Required Jenkins Plugins
1. In Jenkins, go to "Manage Jenkins" > "Manage Plugins"
2. Click "Available" tab
3. Search for and select:
   - "GitHub Integration Plugin"
   - "Pipeline: GitHub"
   - "HTTP Request Plugin"
4. Click "Install without restart"

### Step 13: Make a Test Configuration Change
1. On your local computer, edit the configuration:
   ```bash
   nano casc_configs/jenkins.yaml
   ```

2. Change the system message:
   ```yaml
   jenkins:
     systemMessage: "Jenkins configured via Configuration as Code - Updated!"
     numExecutors: 2
     
     securityRealm:
       local:
         allowsSignup: false
         users:
           - id: "${ADMIN_USER}"
             password: "${ADMIN_PASSWORD}"
   
   tool:
     git:
       installations:
         - name: git
           home: /usr/bin/git
   ```

3. Commit and push:
   ```bash
   git add casc_configs/jenkins.yaml
   git commit -m "Update system message"
   git push
   ```

4. Watch the Jenkins job run automatically (it may take a minute)
5. Refresh your Jenkins dashboard to see the updated system message

## PART 4: Add More Advanced Configuration

### Step 14: Configure Security Settings
1. Edit your configuration file:
   ```bash
   nano casc_configs/jenkins.yaml
   ```

2. Add security settings:
   ```yaml
   jenkins:
     systemMessage: "Jenkins configured via Configuration as Code - Updated!"
     numExecutors: 2
     
     securityRealm:
       local:
         allowsSignup: false
         users:
           - id: "${ADMIN_USER}"
             password: "${ADMIN_PASSWORD}"
     
     authorizationStrategy:
       roleBased:
         roles:
           global:
             - name: "admin"
               description: "Jenkins administrators"
               permissions:
                 - "Overall/Administer"
               assignments:
                 - "${ADMIN_USER}"
             - name: "developer"
               description: "Jenkins developers"
               permissions:
                 - "Overall/Read"
                 - "Job/Build"
                 - "Job/Read"
               assignments:
                 - "developer"
   
   tool:
     git:
       installations:
         - name: git
           home: /usr/bin/git
   ```

3. Commit and push:
   ```bash
   git add casc_configs/jenkins.yaml
   git commit -m "Add security configuration"
   git push
   ```

### Step 15: Add Agent Configuration
1. Edit your configuration file:
   ```bash
   nano casc_configs/jenkins.yaml
   ```

2. Add agent configuration:
   ```yaml
   jenkins:
     systemMessage: "Jenkins configured via Configuration as Code - Updated!"
     numExecutors: 2
     
     securityRealm:
       local:
         allowsSignup: false
         users:
           - id: "${ADMIN_USER}"
             password: "${ADMIN_PASSWORD}"
     
     authorizationStrategy:
       roleBased:
         roles:
           global:
             - name: "admin"
               description: "Jenkins administrators"
               permissions:
                 - "Overall/Administer"
               assignments:
                 - "${ADMIN_USER}"
             - name: "developer"
               description: "Jenkins developers"
               permissions:
                 - "Overall/Read"
                 - "Job/Build"
                 - "Job/Read"
               assignments:
                 - "developer"
     
     nodes:
       - permanent:
           name: "azure-agent-example"
           nodeDescription: "Azure agent example"
           numExecutors: 1
           remoteFS: "/home/jenkins/agent"
           labelString: "azure linux"
           mode: NORMAL
           launcher:
             ssh:
               host: "agent-vm-ip-or-hostname"
               credentialsId: "agent-ssh-credentials"
               port: 22
               sshHostKeyVerificationStrategy:
                 manuallyTrustedKeyVerificationStrategy:
                   requireInitialManualTrust: false
   
   tool:
     git:
       installations:
         - name: git
           home: /usr/bin/git
   ```

3. Commit and push:
   ```bash
   git add casc_configs/jenkins.yaml
   git commit -m "Add agent configuration"
   git push
   ```

## PART 5: Setting Up VirtualBox Agent

### Step 16: Set Up VirtualBox on Your Local Computer
1. Download and install VirtualBox from: https://www.virtualbox.org/wiki/Downloads
2. Download Ubuntu Server ISO from: https://ubuntu.com/download/server

### Step 17: Create a VM for Jenkins Agent
1. Open VirtualBox
2. Click "New"
3. Name: "JenkinsAgent"
4. Type: Linux
5. Version: Ubuntu (64-bit)
6. Memory size: 2048 MB
7. Create a virtual hard disk
8. Choose VDI (VirtualBox Disk Image)
9. Choose "Dynamically allocated"
10. Size: 20 GB
11. Click "Create"

### Step 18: Install Ubuntu on the VM
1. Select your new VM and click "Start"
2. Select the Ubuntu ISO file you downloaded
3. Follow the installation prompts
4. Choose "Install Ubuntu Server"
5. Select your language, location, keyboard layout
6. Create a user:
   - Your name: Jenkins
   - Your server's name: jenkins-agent
   - Username: jenkins
   - Password: [choose a strong password]
7. Choose to install OpenSSH server when prompted
8. Wait for installation to complete and reboot

### Step 19: Configure Port Forwarding for SSH
1. Shut down the VM
2. Select the VM and click "Settings"
3. Go to "Network" > "Adapter 1" > "Advanced" > "Port Forwarding"
4. Click "+" to add a new rule:
   - Name: SSH
   - Protocol: TCP
   - Host IP: 127.0.0.1
   - Host Port: 2222
   - Guest IP: (leave blank)
   - Guest Port: 22
5. Click "OK" and start the VM

### Step 20: Install Java and Required Software
1. SSH into the VM:
   ```bash
   ssh jenkins@127.0.0.1 -p 2222
   ```

2. Install Java and other required software:
   ```bash
   sudo apt update
   sudo apt install -y openjdk-11-jdk-headless
   ```

3. Create a directory for the Jenkins agent:
   ```bash
   mkdir -p ~/jenkins-agent
   ```

4. Generate SSH key for authentication:
   ```bash
   ssh-keygen -t rsa -C "Jenkins Agent Key"
   
   # Display the public key - copy this
   cat ~/.ssh/id_rsa.pub
   
   # Display the private key - copy this
   cat ~/.ssh/id_rsa
   ```

### Step 21: Add the Agent to Jenkins Configuration
1. On your local computer, edit your jenkins.yaml:
   ```bash
   nano casc_configs/jenkins.yaml
   ```

2. Add the VirtualBox agent configuration:
   ```yaml
   credentials:
     system:
       domainCredentials:
         - credentials:
             - basicSSHUserPrivateKey:
                 scope: GLOBAL
                 id: "virtualbox-agent-key"
                 username: "jenkins"
                 privateKeySource:
                   directEntry:
                     privateKey: "${VIRTUALBOX_SSH_KEY}"
   
   jenkins:
     # ... existing configuration
     
     nodes:
       # ... existing agents
       
       - permanent:
           name: "virtualbox-agent"
           nodeDescription: "VirtualBox local agent"
           numExecutors: 1
           remoteFS: "/home/jenkins/jenkins-agent"
           labelString: "virtualbox linux"
           mode: NORMAL
           launcher:
             ssh:
               host: "127.0.0.1"
               credentialsId: "virtualbox-agent-key"
               port: 2222
               sshHostKeyVerificationStrategy:
                 manuallyTrustedKeyVerificationStrategy:
                   requireInitialManualTrust: false
   ```

3. Edit the Jenkins environment variables on the VM:
   ```bash
   sudo nano /etc/default/jenkins
   ```

4. Add the private key (replace with your actual key):
   ```
   VIRTUALBOX_SSH_KEY="-----BEGIN RSA PRIVATE KEY-----
   MIIEpAIBAAKCAQEAx4UbaDzY5xjW6hc9jwN...
   ...
   0000000000000000000000000000000000000
   -----END RSA PRIVATE KEY-----"
   ```

5. Save and exit, then restart Jenkins:
   ```bash
   sudo systemctl restart jenkins
   ```

6. Commit and push your configuration:
   ```bash
   git add casc_configs/jenkins.yaml
   git commit -m "Add VirtualBox agent configuration"
   git push
   ```

## PART 6: Configure Azure Slave Nodes

### Step 22: Create Azure Service Principal
1. Install Azure CLI on your local computer
2. Log in to Azure:
   ```bash
   az login
   ```

3. Create a service principal:
   ```bash
   az ad sp create-for-rbac --name "JenkinsServicePrincipal" --role contributor
   ```

4. Note the output:
   - appId (client ID)
   - password (client secret)
   - tenant

### Step 23: Install Azure VM Agents Plugin
1. In Jenkins, go to "Manage Jenkins" > "Manage Plugins"
2. Click "Available" tab
3. Search for "Azure VM Agents"
4. Select and install without restart

### Step 24: Add Azure Configuration to JCasC
1. Edit your configuration file:
   ```bash
   nano casc_configs/jenkins.yaml
   ```

2. Add Azure credentials and configuration:
   ```yaml
   credentials:
     system:
       domainCredentials:
         - credentials:
             - basicSSHUserPrivateKey:
                 scope: GLOBAL
                 id: "virtualbox-agent-key"
                 username: "jenkins"
                 privateKeySource:
                   directEntry:
                     privateKey: "${VIRTUALBOX_SSH_KEY}"
             - usernamePassword:
                 scope: GLOBAL
                 id: "azure-credentials"
                 username: "${AZURE_CLIENT_ID}"
                 password: "${AZURE_CLIENT_SECRET}"
   
   unclassified:
     azureVMAgents:
       configurationStatus: "pass"
       azureCredentialsId: "azure-credentials"
       resourceGroup: "jenkins-agents"
       maxVirtualMachinesLimit: 10
       deploymentTimeout: 1200
       templates:
         - name: "azure-linux-agent"
           labels: "azure linux"
           location: "eastus"
           virtualMachineSize: "Standard_DS1_v2"
           storageAccountNameReferenceType: "new"
           diskType: "managed"
           newStorageAccountName: "jenkinsagent"
           imageTopLevelType: "basic"
           builtInImage: "Ubuntu 18.04 LTS"
           initScript: |
             #!/bin/bash
             apt update
             apt install -y openjdk-11-jdk-headless
           retentionTimeInMin: 60
   ```

3. Edit the Jenkins environment variables on the VM:
   ```bash
   sudo nano /etc/default/jenkins
   ```

4. Add the Azure credentials:
   ```
   AZURE_CLIENT_ID="your-client-id"
   AZURE_CLIENT_SECRET="your-client-secret"
   ```

5. Save and exit, then restart Jenkins:
   ```bash
   sudo systemctl restart jenkins
   ```

6. Commit and push your configuration:
   ```bash
   git add casc_configs/jenkins.yaml
   git commit -m "Add Azure agent configuration"
   git push
   ```

## PART 7: Create a Complete CI/CD Pipeline

### Step 25: Set Up a Sample Project
1. Create a new GitHub repository for a sample application
2. Add a simple application code (e.g., a Hello World web app)
3. Add a Jenkinsfile in the root of the project:
   ```groovy
   pipeline {
       agent {
           label 'linux'  // Will run on any agent with the 'linux' label
       }
       
       stages {
           stage('Checkout') {
               steps {
                   checkout scm
               }
           }
           
           stage('Build') {
               steps {
                   sh 'echo "Building the application"'
                   // Add actual build commands for your application
               }
           }
           
           stage('Test') {
               steps {
                   sh 'echo "Running tests"'
                   // Add actual test commands
               }
           }
           
           stage('Deploy') {
               agent {
                   label 'azure'  // This stage will run on the Azure agent
               }
               steps {
                   sh 'echo "Deploying to production"'
                   // Add actual deployment commands
               }
           }
       }
   }
   ```

### Step 26: Add the Pipeline to Jenkins Configuration
1. Edit your configuration file:
   ```bash
   nano casc_configs/jenkins.yaml
   ```

2. Add pipeline job configuration:
   ```yaml
   jobs:
     - script: >
         pipelineJob('sample-application') {
           definition {
             cpsScm {
               scm {
                 git {
                   remote {
                     url('https://github.com/YOUR_USERNAME/sample-application.git')
                   }
                   branch('*/main')
                 }
               }
               scriptPath('Jenkinsfile')
             }
           }
           triggers {
             scm('H/5 * * * *')
           }
         }
   ```

3. Commit and push:
   ```bash
   git add casc_configs/jenkins.yaml
   git commit -m "Add sample pipeline job"
   git push
   ```

### Step 27: Set Up Regular Backups
1. SSH into your Jenkins VM:
   ```bash
   ssh -i your-key.pem jenkinsadmin@YOUR_VM_IP_ADDRESS
   ```

2. Create a backup script:
   ```bash
   nano /home/jenkinsadmin/backup-jenkins.sh
   ```

3. Add the following content:
   ```bash
   #!/bin/bash
   DATE=$(date +%Y%m%d_%H%M%S)
   BACKUP_DIR="/home/jenkinsadmin/jenkins-backups"
   JENKINS_HOME="/var/lib/jenkins"
   
   # Create backup directory
   mkdir -p $BACKUP_DIR
   
   # Backup Jenkins home directory
   sudo tar -czf $BACKUP_DIR/jenkins_$DATE.tar.gz -C $(dirname $JENKINS_HOME) $(basename $JENKINS_HOME) --exclude='*/workspace/*'
   
   # Rotate backups (keep only the last 7)
   ls -tp $BACKUP_DIR/jenkins_*.tar.gz | grep -v '/$' | tail -n +8 | xargs -I {} rm -- {}
   ```

4. Make the script executable:
   ```bash
   chmod +x /home/jenkinsadmin/backup-jenkins.sh
   ```

5. Add a cron job to run it daily:
   ```bash
   crontab -e
   ```

6. Add this line:
   ```
   0 2 * * * /home/jenkinsadmin/backup-jenkins.sh
   ```

## PART 8: Docker-based Setup (Alternative Approach)

For a simpler installation with Docker, follow these steps:

### Step 28: Install Docker and Docker Compose on your VM

```bash
# Update packages
sudo apt update

# Install required packages
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update packages again
sudo apt update

# Install Docker
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add your user to the docker group
sudo usermod -aG docker $USER
```

Log out and log back in for group changes to take effect.

### Step 29: Create Docker Compose Configuration

1. Create a project directory:
   ```bash
   mkdir -p jenkins/casc_configs
   cd jenkins
   ```

2. Create a docker-compose.yml file:
   ```bash
   nano docker-compose.yml
   ```

3. Add the following content:
   ```yaml
   version: '3.8'

   services:
     jenkins:
       image: jenkins/jenkins:lts
       container_name: jenkins
       restart: unless-stopped
       privileged: true
       user: root
       ports:
         - "8080:8080"
         - "50000:50000"
       volumes:
         - jenkins_home:/var/jenkins_home
         - /var/run/docker.sock:/var/run/docker.sock
         - /usr/bin/docker:/usr/bin/docker
         - ./casc_configs:/var/jenkins_home/casc_configs
       environment:
         - CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs
         - JENKINS_OPTS="--prefix=/jenkins"
         - JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
         - ADMIN_USER=admin
         - ADMIN_PASSWORD=your_password_here
         # Azure credentials (replace with your values)
         - AZURE_CLIENT_ID=your_client_id_here
         - AZURE_CLIENT_SECRET=your_client_secret_here
         - AZURE_TENANT_ID=your_tenant_id_here
         - AZURE_SUBSCRIPTION_ID=your_subscription_id_here

   volumes:
     jenkins_home:
       driver: local
   ```

4. Create a basic Jenkins configuration:
   ```bash
   nano casc_configs/jenkins.yaml
   ```

5. Add the following content:
   ```yaml
   jenkins:
     systemMessage: "Jenkins configured automatically through Docker Compose and JCasC"
     numExecutors: 2
     
     securityRealm:
       local:
         allowsSignup: false
         users:
           - id: "${ADMIN_USER}"
             password: "${ADMIN_PASSWORD}"
     
     authorizationStrategy:
       roleBased:
         roles:
           global:
             - name: "admin"
               description: "Jenkins administrators"
               permissions:
                 - "Overall/Administer"
               assignments:
                 - "${ADMIN_USER}"

   tool:
     git:
       installations:
         - name: git
           home: git

   # Default plugins to install in addition to the suggested ones
   plugins:
     required:
       - configuration-as-code
       - workflow-aggregator
       - git
       - git-client
       - github-branch-source
       - docker-plugin
       - docker-workflow
       - azure-vm-agents
       - blueocean
       - pipeline-stage-view
       - job-dsl
       - role-strategy
   ```

### Step 30: Start Jenkins with Docker Compose

1. Start Jenkins:
   ```bash
   docker-compose up -d
   ```

2. Access Jenkins at http://YOUR_VM_IP:8080
   - Username: admin
   - Password: the one you set in docker-compose.yml

### Step 31: Add Worker Nodes to the Docker Setup

For VirtualBox VM agents, follow the same steps as in [Part 5](#part-5-setting-up-virtualbox-agent), but update your `casc_configs/jenkins.yaml` in the Docker volume.

For Azure agents, follow the same approach as in [Part 6](#part-6-configure-azure-slave-nodes), but update the configuration in your Docker volume.

### Step 32: Set Up Automatic Backups for Docker-based Jenkins

1. Create a backup script:
   ```bash
   nano backup-jenkins.sh
   ```

2. Add the following content:
   ```bash
   #!/bin/bash
   BACKUP_DIR="/home/$(whoami)/jenkins-backups"
   DATE=$(date +%Y%m%d_%H%M%S)

   mkdir -p $BACKUP_DIR

   docker run --rm --volumes-from jenkins -v $BACKUP_DIR:/backup ubuntu tar czf /backup/jenkins_backup_$DATE.tar.gz /var/jenkins_home

   # Keep only the last 7 backups
   ls -t $BACKUP_DIR/jenkins_backup_*.tar.gz | tail -n +8 | xargs -r rm
   ```

3. Make the script executable:
   ```bash
   chmod +x backup-jenkins.sh
   ```

4. Set up a cron job:
   ```bash
   crontab -e
   # Add: 0 2 * * * /path/to/backup-jenkins.sh
   ```

## Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Jenkins Configuration as Code Plugin](https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/README.md)
- [Azure VM Agents Plugin](https://github.com/jenkinsci/azure-vm-agents-plugin)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)