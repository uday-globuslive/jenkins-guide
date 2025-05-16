#!/bin/bash

# Script to set up GitHub webhooks for JCasC configuration updates
# This script should be run after Jenkins has been configured with JCasC

# Set variables (replace with your own values)
GITHUB_REPO_OWNER="your-org"
GITHUB_REPO_NAME="jenkins-config"
JENKINS_URL="https://your-jenkins-url"
WEBHOOK_SECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)  # Generate random secret

# Exit on error
set -e

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) is not installed. Please install it first."
    echo "See: https://github.com/cli/cli#installation"
    exit 1
fi

# Ensure user is authenticated with GitHub
if ! gh auth status &> /dev/null; then
    echo "Please authenticate with GitHub first:"
    gh auth login
fi

# Create the webhook
echo "Creating GitHub webhook for repository $GITHUB_REPO_OWNER/$GITHUB_REPO_NAME..."
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  repos/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME/hooks \
  -f config[url]="$JENKINS_URL/generic-webhook-trigger/invoke?token=jcasc-update-token" \
  -f config[content_type]=json \
  -f config[secret]="$WEBHOOK_SECRET" \
  -f events[]="push"

# Store webhook secret in Jenkins credentials
echo "Storing webhook secret in Jenkins credentials..."
JENKINS_CRUMB=$(curl -s -u "admin:$JENKINS_ADMIN_PASSWORD" "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
curl -X POST "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" \
  -H "$JENKINS_CRUMB" \
  -u "admin:$JENKINS_ADMIN_PASSWORD" \
  --data-urlencode 'json={
    "": "0",
    "credentials": {
      "scope": "GLOBAL",
      "id": "github-webhook-token",
      "secret": "'"$WEBHOOK_SECRET"'",
      "description": "GitHub webhook secret for JCasC updates",
      "$class": "org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl"
    }
  }'

# Generate reload token and store it in Jenkins credentials
RELOAD_TOKEN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)  # Generate random token
curl -X POST "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" \
  -H "$JENKINS_CRUMB" \
  -u "admin:$JENKINS_ADMIN_PASSWORD" \
  --data-urlencode 'json={
    "": "0",
    "credentials": {
      "scope": "GLOBAL",
      "id": "jcasc-reload-token",
      "secret": "'"$RELOAD_TOKEN"'",
      "description": "Token for authorizing JCasC configuration reloads",
      "$class": "org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl"
    }
  }'

# Set environment variable for reload token
echo "Setting CASC_RELOAD_TOKEN environment variable..."
JENKINS_JAVA_OPTS="${JENKINS_JAVA_OPTS} -DCASC_RELOAD_TOKEN=${RELOAD_TOKEN}"

# Instructions for the user
echo
echo "========== SETUP COMPLETE =========="
echo
echo "The GitHub webhook has been created and configured."
echo
echo "Webhook details:"
echo "  URL: $JENKINS_URL/generic-webhook-trigger/invoke?token=jcasc-update-token"
echo "  Secret: $WEBHOOK_SECRET (stored in Jenkins as 'github-webhook-token')"
echo "  Events: push"
echo
echo "Reload token has been generated and stored in Jenkins as 'jcasc-reload-token'"
echo
echo "IMPORTANT: To complete the setup, add the following to your Jenkins environment:"
echo "CASC_RELOAD_TOKEN=$RELOAD_TOKEN"
echo
echo "If using Jenkins in a container, add this to your environment variables."
echo "If using systemd, add this to the Jenkins service configuration."
echo
echo "To test the webhook, make a change to your configuration repository and push."
echo "Check the 'JCasC-Config-Updater' job in Jenkins to verify it was triggered."
echo