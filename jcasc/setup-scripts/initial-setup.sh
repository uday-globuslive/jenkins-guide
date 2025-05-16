#!/bin/bash

# Initial setup script for JCasC with GitHub webhook integration
# This script installs required plugins and initializes JCasC

# Exit on error
set -e

# Set variables (replace with your own values)
JENKINS_URL=${JENKINS_URL:-"http://localhost:8080"}
ADMIN_USER=${ADMIN_USER:-"admin"}
ADMIN_PASS=${ADMIN_PASS:-"admin"}

# Function to install Jenkins plugins
install_plugins() {
    local plugins=(
        "configuration-as-code"
        "git"
        "github"
        "github-branch-source"
        "generic-webhook-trigger"
        "http_request"
        "credentials"
        "job-dsl"
        "pipeline-utility-steps"
        "email-ext"
    )
    
    echo "Installing plugins..."
    
    # Get CSRF crumb for API requests
    CRUMB=$(curl -s --user "${ADMIN_USER}:${ADMIN_PASS}" "${JENKINS_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
    
    for plugin in "${plugins[@]}"; do
        echo "Installing plugin: $plugin"
        curl -X POST -H "$CRUMB" --user "${ADMIN_USER}:${ADMIN_PASS}" \
            "${JENKINS_URL}/pluginManager/installNecessaryPlugins" \
            --data "<jenkins><install plugin=\"${plugin}@latest\" /></jenkins>"
    done
    
    echo "Waiting for plugins to install..."
    sleep 30
    
    # Restart Jenkins
    curl -X POST -H "$CRUMB" --user "${ADMIN_USER}:${ADMIN_PASS}" "${JENKINS_URL}/safeRestart"
    
    # Wait for Jenkins to come back up
    echo "Restarting Jenkins..."
    while ! curl -s --head --request GET "${JENKINS_URL}" | grep "200" > /dev/null; do
        echo "Waiting for Jenkins to restart..."
        sleep 5
    done
    
    echo "Jenkins restarted successfully."
}

# Create initial JCasC directory structure
create_jcasc_structure() {
    echo "Creating JCasC directory structure..."
    
    # Create directories
    mkdir -p /var/jenkins_home/jcasc
    mkdir -p /var/jenkins_home/jcasc/backups
    mkdir -p /var/jenkins_home/init.groovy.d
    
    # Copy configuration files
    cp jenkins.yaml /var/jenkins_home/jcasc/
    cp jcasc-reload-http-endpoint.groovy /var/jenkins_home/init.groovy.d/
    
    echo "JCasC directory structure created."
}

# Set up environment variables
setup_environment() {
    echo "Setting up environment variables..."
    
    # Create .env file
    cat > .env << EOF
JENKINS_URL=${JENKINS_URL}
ADMIN_PASSWORD=${ADMIN_PASS}
GITHUB_USERNAME=your-github-username
GITHUB_TOKEN=your-github-token
GITHUB_WEBHOOK_SECRET=your-webhook-secret
CASC_RELOAD_TOKEN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
JCASC_GIT_REPO=https://github.com/your-org/jenkins-config.git
JCASC_GIT_BRANCH=main
EOF
    
    echo "Environment variables set up in .env file."
    echo "Important: Replace placeholder values in .env with your actual credentials."
}

# Main execution
echo "Starting Jenkins JCasC setup..."

# Check if running in Jenkins container
if [ -d "/var/jenkins_home" ]; then
    create_jcasc_structure
fi

# Install plugins
install_plugins

# Set up environment
setup_environment

echo "Setup completed!"
echo "Next steps:"
echo "1. Update the .env file with your actual credentials"
echo "2. Run the jcasc-webhook-setup.sh script to configure GitHub webhooks"
echo "3. Start Jenkins with JCasC enabled using docker-compose.yml"
echo "4. Verify configuration by visiting ${JENKINS_URL}/configuration-as-code/"