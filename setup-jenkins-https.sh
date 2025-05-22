#!/bin/bash

# Main setup script for Jenkins with HTTPS on VMware Workstation

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

echo "=== Jenkins HTTPS Setup on VMware Workstation ==="
echo "This script will set up Jenkins with HTTPS using self-signed certificates"
echo "==============================================="

# Make all scripts executable
chmod +x setup-vmware.sh setup-ssl.sh setup-nginx.sh setup-local-dns.sh

# Step 1: Configure Jenkins domain information
echo "Step 1: Configuring Jenkins domain information..."
read -p "Enter domain name for Jenkins (e.g., jenkins.local): " JENKINS_DOMAIN
read -p "Enter admin password for Jenkins: " ADMIN_PASSWORD

# Create hostname information file
echo "Creating hostname information file..."
cat > jenkins-hostname.info << EOF
JENKINS_DOMAIN=$JENKINS_DOMAIN
JENKINS_IP=$(hostname -I | awk '{print $1}')
EOF

# Step 2: Update the docker-compose-https.yml file
echo "Step 2: Updating Docker Compose configuration..."
cp docker-compose-https.yml docker-compose.yml
sed -i "s/admin_password_here/$ADMIN_PASSWORD/g" docker-compose.yml

# Step 3: Set up SSL certificates
echo "Step 3: Setting up SSL certificates..."
./setup-ssl.sh

# Step 4: Set up Nginx as a reverse proxy
echo "Step 4: Setting up Nginx as a reverse proxy..."
./setup-nginx.sh

# Step 5: Configure local DNS
echo "Step 5: Configuring local DNS..."
./setup-local-dns.sh

# Step 6: Use HTTPS configuration for Jenkins
echo "Step 6: Updating Jenkins configuration for HTTPS..."
cp casc_configs/jenkins-https.yaml casc_configs/jenkins.yaml

# Step 7: Start Jenkins
echo "Step 7: Starting Jenkins..."
docker-compose down
docker-compose up -d

# Step 8: Wait for Jenkins to start
echo "Step 8: Waiting for Jenkins to start..."
sleep 30

echo "==============================================="
echo "Jenkins HTTPS setup complete!"
echo ""
echo "Your Jenkins instance is now available at:"
echo "https://$JENKINS_DOMAIN"
echo ""
echo "Username: admin"
echo "Password: $ADMIN_PASSWORD"
echo ""
echo "To manage the Jenkins service:"
echo "- Stop: docker-compose down"
echo "- Start: docker-compose up -d"
echo "- View logs: docker-compose logs -f jenkins"
echo ""
echo "Client setup instructions are available in: client-dns-setup.txt"
echo "==============================================="

# Create a testing script
cat > test-jenkins-https.sh << 'EOF'
#!/bin/bash

# Script to test Jenkins HTTPS setup

echo "=== Jenkins HTTPS Test ==="
echo "This script will test the Jenkins HTTPS setup"
echo "==============================================="

# Load host information
if [ ! -f "jenkins-hostname.info" ]; then
  echo "Hostname information file not found."
  exit 1
fi

source jenkins-hostname.info

# Test DNS resolution
echo "Testing DNS resolution..."
ping -c 1 $JENKINS_DOMAIN
if [ $? -ne 0 ]; then
  echo "DNS resolution failed. Check /etc/hosts entry."
  exit 1
fi

# Test HTTPS connection
echo "Testing HTTPS connection..."
curl -k -I https://$JENKINS_DOMAIN
if [ $? -ne 0 ]; then
  echo "HTTPS connection failed. Check Nginx and SSL configuration."
  exit 1
fi

echo "==============================================="
echo "All tests passed! Jenkins is accessible via HTTPS."
echo "==============================================="
EOF

chmod +x test-jenkins-https.sh
chown $SUDO_USER:$SUDO_USER test-jenkins-https.sh

echo "A test script has been created: test-jenkins-https.sh"
echo "Run it to verify your HTTPS setup is working properly."