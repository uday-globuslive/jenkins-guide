#!/bin/bash

# Setup script for configuring local DNS for Jenkins

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

echo "=== Jenkins Local DNS Setup ==="
echo "This script will configure local DNS for Jenkins"
echo "==============================================="

# Load host information
if [ ! -f "jenkins-hostname.info" ]; then
  echo "Hostname information file not found. Please run setup-vmware.sh first."
  exit 1
fi

source jenkins-hostname.info

# Ensure hosts entry exists
if ! grep -q "$JENKINS_DOMAIN" /etc/hosts; then
  echo "Adding $JENKINS_DOMAIN to /etc/hosts..."
  echo "$JENKINS_IP  $JENKINS_DOMAIN" >> /etc/hosts
else
  echo "$JENKINS_DOMAIN already exists in /etc/hosts"
  # Update IP if needed
  sed -i "s/.*$JENKINS_DOMAIN/$JENKINS_IP  $JENKINS_DOMAIN/" /etc/hosts
fi

# Create a guide for client machines
echo "Creating client setup guide..."
cat > client-dns-setup.txt << EOF
=== Jenkins Client DNS Setup Guide ===

To access Jenkins using the domain name from your client machines, 
add the following entry to your hosts file:

$JENKINS_IP  $JENKINS_DOMAIN

Host file locations:
- Windows: C:\\Windows\\System32\\drivers\\etc\\hosts
- Mac/Linux: /etc/hosts

Windows instructions:
1. Open Notepad as Administrator
2. File > Open > Navigate to C:\\Windows\\System32\\drivers\\etc
3. Change file filter to "All Files (*.*)"
4. Open the "hosts" file
5. Add the line above and save

Mac/Linux instructions:
1. Open Terminal
2. Run: sudo nano /etc/hosts
3. Add the line above
4. Press Ctrl+X to exit, Y to save, and Enter to confirm

After adding the entry, you can access Jenkins at:
https://$JENKINS_DOMAIN
EOF

echo "==============================================="
echo "Local DNS configuration complete!"
echo ""
echo "Your Jenkins instance is now available at:"
echo "https://$JENKINS_DOMAIN"
echo ""
echo "A guide for client machines has been created: client-dns-setup.txt"
echo "==============================================="