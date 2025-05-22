#!/bin/bash

# Setup script for creating self-signed SSL certificates for Jenkins

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

echo "=== Jenkins SSL Certificate Setup ==="
echo "This script will create self-signed SSL certificates for Jenkins"
echo "==============================================="

# Check if hostname information file exists
if [ ! -f "jenkins-hostname.info" ]; then
  echo "Hostname information file not found. Please run setup-vmware.sh first."
  read -p "Enter domain name for Jenkins (e.g., jenkins.local): " JENKINS_DOMAIN
else
  source jenkins-hostname.info
  echo "Using domain name: $JENKINS_DOMAIN"
fi

# Step 1: Create SSL directory
echo "Creating SSL directory..."
mkdir -p ssl
chown -R $SUDO_USER:$SUDO_USER ssl

# Step 2: Generate a private key
echo "Generating private key..."
openssl genrsa -out ssl/jenkins.key 2048

# Step 3: Create a configuration file for the certificate
echo "Creating OpenSSL configuration file..."
cat > ssl/jenkins.cnf << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = v3_req

[dn]
C=US
ST=State
L=City
O=Organization
OU=Organizational Unit
CN=$JENKINS_DOMAIN

[v3_req]
subjectAltName = @alt_names
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[alt_names]
DNS.1 = $JENKINS_DOMAIN
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF

# Step 4: Generate the certificate
echo "Generating self-signed certificate..."
openssl req -new -x509 -key ssl/jenkins.key -out ssl/jenkins.crt -days 365 -config ssl/jenkins.cnf

# Step 5: Set proper permissions
echo "Setting proper permissions..."
chmod 600 ssl/jenkins.key
chmod 644 ssl/jenkins.crt

# Step 6: Create PEM file (combined cert and key)
echo "Creating PEM file..."
cat ssl/jenkins.crt ssl/jenkins.key > ssl/jenkins.pem
chmod 600 ssl/jenkins.pem

echo "==============================================="
echo "SSL certificate creation complete!"
echo "Certificate: ssl/jenkins.crt"
echo "Private key: ssl/jenkins.key"
echo "Combined PEM: ssl/jenkins.pem"
echo ""
echo "Next step: Run setup-nginx.sh to configure Nginx as a reverse proxy"
echo "==============================================="

# Display information to add the certificate to client systems
echo "To add this certificate to your client systems:"
echo ""
echo "For Windows:"
echo "1. Open the certificate file (jenkins.crt)"
echo "2. Click 'Install Certificate'"
echo "3. Select 'Local Machine' > 'Place all certificates in the following store' > 'Trusted Root Certification Authorities'"
echo ""
echo "For macOS:"
echo "1. Double-click the certificate file (jenkins.crt)"
echo "2. Add it to the System keychain"
echo "3. Set trust setting to 'Always Trust'"
echo ""
echo "For Linux:"
echo "1. Copy the certificate to /usr/local/share/ca-certificates/jenkins.crt"
echo "2. Run: sudo update-ca-certificates"
echo "==============================================="