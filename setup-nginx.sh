#!/bin/bash

# Setup script for configuring Nginx as a reverse proxy for Jenkins with HTTPS

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

echo "=== Jenkins Nginx HTTPS Setup ==="
echo "This script will configure Nginx as a reverse proxy for Jenkins with HTTPS"
echo "==============================================="

# Check if hostname information file exists
if [ ! -f "jenkins-hostname.info" ]; then
  echo "Hostname information file not found. Please run setup-vmware.sh first."
  read -p "Enter domain name for Jenkins (e.g., jenkins.local): " JENKINS_DOMAIN
  JENKINS_IP=$(hostname -I | awk '{print $1}')
else
  source jenkins-hostname.info
  echo "Using domain name: $JENKINS_DOMAIN"
  echo "Jenkins IP: $JENKINS_IP"
fi

# Check if SSL certificates exist
if [ ! -f "ssl/jenkins.crt" ] || [ ! -f "ssl/jenkins.key" ]; then
  echo "SSL certificates not found. Please run setup-ssl.sh first."
  exit 1
fi

# Step 1: Install Nginx
echo "Installing Nginx..."
apt update
apt install -y nginx

# Step 2: Create Nginx configuration for Jenkins
echo "Creating Nginx configuration for Jenkins..."
cat > /etc/nginx/sites-available/jenkins << EOF
server {
    listen 80;
    server_name $JENKINS_DOMAIN;
    
    # Redirect all HTTP requests to HTTPS
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $JENKINS_DOMAIN;

    ssl_certificate     /home/vmadmin/jenkins/ssl/jenkins.crt;
    ssl_certificate_key /home/vmadmin/jenkins/ssl/jenkins.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout 10m;
    ssl_session_cache shared:SSL:10m;

    # Disable strict SSL checking when using self-signed certificates in dev/test
    # Comment out these lines in production with a proper certificate
    ssl_verify_client off;
    
    access_log /var/log/nginx/jenkins.access.log;
    error_log /var/log/nginx/jenkins.error.log;

    # Pass all requests to Jenkins
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Required for Jenkins webhooks
        proxy_http_version 1.1;
        proxy_request_buffering off;
        proxy_buffering off;
        
        # Required for Jenkins CLI
        proxy_set_header Connection "";
        
        # Increase timeouts for long-running CLI commands
        proxy_connect_timeout 150;
        proxy_send_timeout 150;
        proxy_read_timeout 150;
        
        # Required to handle large headers from Jenkins
        proxy_buffer_size 8k;
        proxy_buffers 32 8k;
    }
}
EOF

# Step 3: Enable the Jenkins site
echo "Enabling Nginx site configuration..."
ln -sf /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Step 4: Test Nginx configuration
echo "Testing Nginx configuration..."
nginx -t

# Step 5: Restart Nginx to apply changes
echo "Restarting Nginx..."
systemctl restart nginx
systemctl enable nginx

# Step 6: Configure firewall (if enabled)
echo "Configuring firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 'Nginx Full'
    ufw status
fi

echo "==============================================="
echo "Nginx configuration complete!"
echo ""
echo "Your Jenkins instance is now available at:"
echo "https://$JENKINS_DOMAIN"
echo ""
echo "Don't forget to update your local hosts file with:"
echo "$JENKINS_IP  $JENKINS_DOMAIN"
echo "==============================================="

# Step 7: Create a local DNS setup script for VMware
echo "Creating local DNS setup script..."
cat > setup-local-dns.sh << 'EOF'
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

echo "==============================================="
echo "Local DNS configuration complete!"
echo ""
echo "Your Jenkins instance is now available at:"
echo "https://$JENKINS_DOMAIN"
echo ""
echo "Instructions for client machines:"
echo "Add the following line to your hosts file:"
echo "$JENKINS_IP  $JENKINS_DOMAIN"
echo ""
echo "Windows: C:\\Windows\\System32\\drivers\\etc\\hosts"
echo "Mac/Linux: /etc/hosts"
echo "==============================================="
EOF

chmod +x setup-local-dns.sh
chown $SUDO_USER:$SUDO_USER setup-local-dns.sh