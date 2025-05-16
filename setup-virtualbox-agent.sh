#!/bin/bash

# Script to set up Jenkins agent on a VirtualBox VM

echo "=== Jenkins VirtualBox Agent Setup ==="
echo "This script will guide you through setting up a Jenkins agent on a VirtualBox VM"
echo "==============================================="

# Step 1: Install required packages
echo "Updating system and installing required packages..."
sudo apt update
sudo apt install -y openjdk-11-jdk-headless openssh-server

# Step 2: Create Jenkins user if it doesn't exist
if id "jenkins" &>/dev/null; then
    echo "Jenkins user already exists"
else
    echo "Creating jenkins user..."
    sudo adduser --disabled-password --gecos "" jenkins
    echo "jenkins:jenkins" | sudo chpasswd
fi

# Step 3: Create agent directory
echo "Creating agent directory..."
sudo mkdir -p /home/jenkins/jenkins-agent
sudo chown -R jenkins:jenkins /home/jenkins/jenkins-agent

# Step 4: Configure SSH access
echo "Configuring SSH access..."
sudo mkdir -p /home/jenkins/.ssh
sudo chmod 700 /home/jenkins/.ssh

echo "Generating SSH key pair for agent authentication..."
sudo -u jenkins ssh-keygen -t rsa -f /home/jenkins/.ssh/id_rsa -N ""

# Display the public key to copy to Jenkins master
echo "==============================================="
echo "Here is the public key to add to Jenkins master:"
echo "==============================================="
cat /home/jenkins/.ssh/id_rsa.pub
echo "==============================================="

# Display the private key to add to Jenkins credentials
echo "Here is the private key to add to Jenkins credentials:"
echo "==============================================="
cat /home/jenkins/.ssh/id_rsa
echo "==============================================="

# Step 5: Configure SSH authorized_keys
echo "Please enter the Jenkins master's public key (paste and press Enter, then Ctrl+D):"
tempfile=$(mktemp)
cat > $tempfile
sudo mv $tempfile /home/jenkins/.ssh/authorized_keys
sudo chown jenkins:jenkins /home/jenkins/.ssh/authorized_keys
sudo chmod 600 /home/jenkins/.ssh/authorized_keys

# Step 6: Enable and start SSH service
echo "Ensuring SSH service is enabled and running..."
sudo systemctl enable ssh
sudo systemctl restart ssh

# Step 7: Set up the agent service for JNLP (alternative method)
echo "Setting up the agent service for JNLP connection (alternative method)..."
echo "Please enter the Jenkins JNLP secret (or leave blank for SSH-only setup):"
read jnlp_secret

if [ ! -z "$jnlp_secret" ]; then
    echo "Downloading Jenkins agent JAR..."
    echo "Please enter the Jenkins master URL (e.g., http://jenkins-master:8080):"
    read jenkins_url
    
    echo "Please enter the agent name as configured in Jenkins:"
    read agent_name
    
    sudo -u jenkins curl -sO $jenkins_url/jnlpJars/agent.jar
    sudo mv agent.jar /home/jenkins/jenkins-agent/
    
    # Create systemd service file
    cat > jenkins-agent.service << EOF
[Unit]
Description=Jenkins Agent
After=network.target

[Service]
User=jenkins
WorkingDirectory=/home/jenkins/jenkins-agent
ExecStart=/usr/bin/java -jar /home/jenkins/jenkins-agent/agent.jar -jnlpUrl $jenkins_url/computer/$agent_name/slave-agent.jnlp -secret $jnlp_secret -workDir "/home/jenkins/jenkins-agent"
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    
    sudo mv jenkins-agent.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable jenkins-agent
    sudo systemctl start jenkins-agent
    
    echo "JNLP agent service installed and started"
fi

# Step 8: Display IP address for use in Jenkins configuration
ip_address=$(hostname -I | awk '{print $1}')
echo "==============================================="
echo "Agent setup complete!"
echo ""
echo "Use the following information in your Jenkins Configuration as Code:"
echo "Node name: $(hostname)"
echo "IP address: $ip_address"
echo "SSH port: 22"
echo "Remote root directory: /home/jenkins/jenkins-agent"
echo "Label: virtualbox"
echo ""
echo "Don't forget to add the private key to Jenkins credentials"
echo "and configure SSH host verification strategy to use the 'Non verifying' option"
echo "==============================================="