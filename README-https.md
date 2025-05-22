# Jenkins HTTPS Setup with Self-Signed Certificates

This guide provides step-by-step instructions for setting up Jenkins with HTTPS using self-signed certificates on VMware Workstation, complete with local DNS configuration and proper security.

## Overview

This setup includes:

- Jenkins installation using Docker Compose
- Configuration as Code (JCasC) for Jenkins
- Self-signed SSL certificates for HTTPS
- Nginx as a reverse proxy for HTTPS
- Local DNS configuration for convenient access
- VMware Workstation-specific configuration

## Prerequisites

- Ubuntu-based VM running on VMware Workstation (Ubuntu 20.04 or higher recommended)
- Sudo/root access on the VM
- Network connectivity for package installation
- VMware Workstation 15 or higher

## Quick Setup

For a complete automated setup, run:

```bash
sudo ./setup-jenkins-https.sh
```

This script will guide you through the entire process, asking for:
- Domain name for Jenkins (e.g., jenkins.local)
- Admin password for Jenkins

## Manual Setup Process

If you prefer to perform the setup step by step, follow these instructions:

### Step 1: Configure VM and Install Dependencies

```bash
sudo ./setup-vmware.sh
```

This script:
- Installs Docker and Docker Compose
- Sets up directories for Jenkins
- Configures initial permissions
- Creates an initial Docker Compose configuration

### Step 2: Generate Self-Signed SSL Certificates

```bash
sudo ./setup-ssl.sh
```

This script:
- Creates a private key for your Jenkins server
- Generates a self-signed certificate
- Sets proper permissions for security
- Creates combined certificate files for different purposes

### Step 3: Set Up Nginx as a Reverse Proxy

```bash
sudo ./setup-nginx.sh
```

This script:
- Installs Nginx
- Configures Nginx as a reverse proxy
- Sets up SSL termination
- Redirects HTTP to HTTPS
- Configures security headers

### Step 4: Configure Local DNS

```bash
sudo ./setup-local-dns.sh
```

This script:
- Adds an entry to your hosts file
- Creates instructions for client machines
- Ensures domain name resolution works

### Step 5: Test the Setup

```bash
./test-jenkins-https.sh
```

This script:
- Tests DNS resolution
- Verifies HTTPS connectivity
- Ensures Jenkins is properly configured

## Directory Structure

```
jenkins/
├── docker-compose.yml             # Docker Compose configuration
├── docker-compose-https.yml       # HTTPS-specific Docker Compose template
├── setup-jenkins-https.sh         # Main setup script
├── setup-vmware.sh                # VMware-specific setup script
├── setup-ssl.sh                   # SSL certificate generation script
├── setup-nginx.sh                 # Nginx configuration script
├── setup-local-dns.sh             # Local DNS configuration script
├── test-jenkins-https.sh          # Testing script
├── casc_configs/                  # Jenkins Configuration as Code files
│   ├── jenkins.yaml               # Main Jenkins configuration
│   ├── jenkins-https.yaml         # HTTPS-specific configuration template
│   ├── credentials.yaml           # Credentials configuration
├── ssl/                           # SSL certificate files
│   ├── jenkins.key                # Private key
│   ├── jenkins.crt                # Certificate
│   ├── jenkins.pem                # Combined key and certificate
│   └── jenkins.cnf                # OpenSSL configuration
└── client-dns-setup.txt           # Instructions for client machines
```

## Client Machine Configuration

To access Jenkins from a client machine:

1. Add an entry to your hosts file:
   ```
   <jenkins-vm-ip>  jenkins.local
   ```

2. Import the SSL certificate to your trust store:
   - Windows: Add to Trusted Root Certification Authorities
   - macOS: Add to System keychain and set to "Always Trust"
   - Linux: Add to system CA certificates

3. Access Jenkins at `https://jenkins.local`

## Security Considerations

- This setup uses self-signed certificates, which are appropriate for development/testing environments but not for production
- For production, replace self-signed certificates with proper certificates from a trusted CA
- Consider implementing additional security measures such as:
  - Firewall rules
  - Jenkins security hardening
  - Regular security updates

## Troubleshooting

### Certificate Issues

If you see certificate warnings:
- Ensure you've imported the certificate to your client's trust store
- Verify the certificate was created with the correct common name (CN)
- Check Nginx SSL configuration

### Connection Issues

If you can't connect to Jenkins:
- Verify the VM is running and accessible on the network
- Check that Nginx is running: `systemctl status nginx`
- Ensure Docker containers are running: `docker-compose ps`
- Check firewall settings: `ufw status`

### Docker Issues

If Docker containers won't start:
- Check Docker logs: `docker-compose logs jenkins`
- Verify Docker service is running: `systemctl status docker`
- Ensure proper permissions on mounted volumes

## Management Commands

```bash
# Start Jenkins
docker-compose up -d

# Stop Jenkins
docker-compose down

# View logs
docker-compose logs -f jenkins

# Restart Nginx
sudo systemctl restart nginx

# Check Nginx configuration
sudo nginx -t

# Test HTTPS connectivity
curl -k -I https://jenkins.local
```

## Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Jenkins Configuration as Code](https://github.com/jenkinsci/configuration-as-code-plugin)
- [Nginx HTTPS Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [OpenSSL Certificate Creation](https://www.openssl.org/docs/man1.1.1/man1/openssl-req.html)