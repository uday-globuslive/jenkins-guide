#!/bin/bash

# Setup script for Jenkins with Docker Compose and Configuration as Code

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

echo "=== Jenkins Docker Setup ==="
echo "This script will install Docker, Docker Compose, and set up Jenkins"
echo "==============================================="

# Step 1: Update the system
echo "Updating system packages..."
apt update
apt upgrade -y

# Step 2: Install required packages
echo "Installing required packages..."
apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg

# Step 3: Install Docker
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install -y docker-ce docker-ce-cli containerd.io

# Step 4: Install Docker Compose
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Step 5: Create the jenkins group and add the current user to it
echo "Setting up Jenkins user permissions..."
groupadd -f docker
usermod -aG docker $SUDO_USER

# Step 6: Create directories for Jenkins configuration
echo "Creating Jenkins configuration directories..."
mkdir -p casc_configs
chown -R $SUDO_USER:$SUDO_USER casc_configs

# Step 7: Set credentials in docker-compose.yml
echo "Setting up credentials in docker-compose.yml..."
read -p "Enter admin password for Jenkins: " ADMIN_PASSWORD
read -p "Enter Azure Client ID (leave blank if not using Azure): " AZURE_CLIENT_ID
read -p "Enter Azure Client Secret (leave blank if not using Azure): " AZURE_CLIENT_SECRET
read -p "Enter Azure Tenant ID (leave blank if not using Azure): " AZURE_TENANT_ID
read -p "Enter Azure Subscription ID (leave blank if not using Azure): " AZURE_SUBSCRIPTION_ID

# Update the docker-compose.yml file with the provided credentials
sed -i "s/admin_password_here/$ADMIN_PASSWORD/g" docker-compose.yml
if [ ! -z "$AZURE_CLIENT_ID" ]; then
  sed -i "s/your_client_id_here/$AZURE_CLIENT_ID/g" docker-compose.yml
  sed -i "s/your_client_secret_here/$AZURE_CLIENT_SECRET/g" docker-compose.yml
  sed -i "s/your_tenant_id_here/$AZURE_TENANT_ID/g" docker-compose.yml
  sed -i "s/your_subscription_id_here/$AZURE_SUBSCRIPTION_ID/g" docker-compose.yml
fi

# Step 8: Start Jenkins
echo "Starting Jenkins..."
docker-compose up -d

# Step 9: Wait for Jenkins to start and display the URL
echo "Waiting for Jenkins to start..."
sleep 30
echo "==============================================="
echo "Jenkins is starting at http://$(hostname -I | awk '{print $1}'):8080"
echo "Username: admin"
echo "Password: $ADMIN_PASSWORD"
echo ""
echo "To stop Jenkins: docker-compose down"
echo "To start Jenkins: docker-compose up -d"
echo "To view logs: docker-compose logs -f jenkins"
echo "==============================================="

# Create a helper script for adding more workers
cat > add_worker.sh << 'EOL'
#!/bin/bash

# This script helps add a new worker node to Jenkins

echo "=== Add Jenkins Worker Node ==="
echo "This script will guide you through adding a new worker node to Jenkins"
echo "==============================================="

read -p "Enter worker node name: " NODE_NAME
read -p "Enter worker node IP address: " NODE_IP
read -p "Enter SSH username: " SSH_USER
read -s -p "Enter SSH password (leave empty for key-based auth): " SSH_PASS
echo ""

# Generate the worker configuration in YAML format
cat >> casc_configs/workers.yaml << EOF

  # Worker node: $NODE_NAME
  nodes:
    - permanent:
        name: "$NODE_NAME"
        nodeDescription: "Worker node at $NODE_IP"
        numExecutors: 2
        remoteFS: "/home/$SSH_USER/jenkins-agent"
        labelString: "worker $NODE_NAME"
        mode: NORMAL
        launcher:
          ssh:
            host: "$NODE_IP"
            credentialsId: "${NODE_NAME}-credentials"
            port: 22
            sshHostKeyVerificationStrategy:
              manuallyTrustedKeyVerificationStrategy:
                requireInitialManualTrust: false
EOF

# Add credentials if a password was provided
if [ ! -z "$SSH_PASS" ]; then
  cat >> casc_configs/credentials.yaml << EOF

  # Credentials for worker node $NODE_NAME
  credentials:
    system:
      domainCredentials:
        - credentials:
            - usernamePassword:
                scope: GLOBAL
                id: "${NODE_NAME}-credentials"
                username: "$SSH_USER"
                password: "$SSH_PASS"
                description: "Credentials for $NODE_NAME worker node"
EOF
else
  echo "For key-based authentication, add the credentials manually in Jenkins"
fi

echo "==============================================="
echo "Worker node configuration added!"
echo "The node will be added the next time Jenkins restarts or you apply the configuration"
echo "Restart Jenkins with: docker-compose restart jenkins"
echo "==============================================="
EOL

chmod +x add_worker.sh
chown $SUDO_USER:$SUDO_USER add_worker.sh

# Create a script for backing up Jenkins
cat > backup_jenkins.sh << 'EOL'
#!/bin/bash

# This script backs up Jenkins home directory

BACKUP_DIR="/home/$(whoami)/jenkins-backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "Backing up Jenkins to $BACKUP_DIR/jenkins_backup_$DATE.tar.gz"
docker run --rm --volumes-from jenkins -v $BACKUP_DIR:/backup ubuntu tar czf /backup/jenkins_backup_$DATE.tar.gz /var/jenkins_home

# Keep only the last 7 backups
echo "Removing old backups..."
ls -t $BACKUP_DIR/jenkins_backup_*.tar.gz | tail -n +8 | xargs -r rm

echo "Backup completed: $BACKUP_DIR/jenkins_backup_$DATE.tar.gz"
EOL

chmod +x backup_jenkins.sh
chown $SUDO_USER:$SUDO_USER backup_jenkins.sh

echo "Setup completed! Additional helper scripts created:"
echo "- add_worker.sh: Script to add worker nodes"
echo "- backup_jenkins.sh: Script to backup Jenkins"
echo ""
echo "Add a scheduled backup with: crontab -e"
echo "Example (daily at 2 AM): 0 2 * * * /path/to/backup_jenkins.sh"