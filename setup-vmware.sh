#!/bin/bash

# Setup script for Jenkins with Docker Compose on VMware Workstation
# This script sets up Jenkins with Docker Compose on a VMware Workstation VM

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

echo "=== Jenkins VMware Workstation Setup ==="
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

# Step 5: Create the docker group and add the current user to it
echo "Setting up Docker user permissions..."
groupadd -f docker
usermod -aG docker $SUDO_USER

# Step 6: Create directories for Jenkins configuration
echo "Creating Jenkins configuration directories..."
mkdir -p casc_configs
chown -R $SUDO_USER:$SUDO_USER casc_configs

# Step 7: Set credentials in docker-compose.yml
echo "Setting up credentials in docker-compose.yml..."
read -p "Enter admin password for Jenkins: " ADMIN_PASSWORD
read -p "Enter domain name for Jenkins (e.g., jenkins.local): " JENKINS_DOMAIN

# Update the docker-compose.yml file with the provided credentials
sed -i "s/admin_password_here/$ADMIN_PASSWORD/g" docker-compose.yml

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
echo "Domain name: $JENKINS_DOMAIN"
echo ""
echo "To stop Jenkins: docker-compose down"
echo "To start Jenkins: docker-compose up -d"
echo "To view logs: docker-compose logs -f jenkins"
echo "==============================================="

# Create hostname information file
echo "Creating hostname information file..."
cat > jenkins-hostname.info << EOF
JENKINS_DOMAIN=$JENKINS_DOMAIN
JENKINS_IP=$(hostname -I | awk '{print $1}')
EOF

echo "Next steps:"
echo "1. Add the following entry to your host machine's hosts file:"
echo "   $(hostname -I | awk '{print $1}')  $JENKINS_DOMAIN"
echo "2. Run the setup-ssl.sh script to create SSL certificates"
echo "3. Run the setup-nginx.sh script to configure Nginx as a reverse proxy"
echo "==============================================="