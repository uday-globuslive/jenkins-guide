# Jenkins with Docker Compose and Configuration as Code

This guide provides step-by-step instructions for setting up Jenkins using Docker Compose with Configuration as Code, making it easy to deploy and manage Jenkins with all its configuration stored in code.

## Quick Start

1. Make sure you have proper permissions on all scripts:
   ```bash
   chmod +x setup.sh add_worker.sh backup_jenkins.sh setup-virtualbox-agent.sh
   ```

2. Run the setup script:
   ```bash
   sudo ./setup.sh
   ```

3. Access Jenkins at http://YOUR_SERVER_IP:8080

## Directory Structure

```
jenkins/
├── docker-compose.yml         # Docker Compose configuration
├── setup.sh                   # Main setup script
├── add_worker.sh              # Helper script to add worker nodes
├── backup_jenkins.sh          # Script for backing up Jenkins
├── setup-virtualbox-agent.sh  # Script to set up a VirtualBox agent
└── casc_configs/              # Jenkins Configuration as Code files
    ├── jenkins.yaml           # Main Jenkins configuration
    ├── credentials.yaml       # Credentials configuration
    └── workers.yaml           # Worker nodes configuration
```

## Docker Compose Configuration

The `docker-compose.yml` file sets up Jenkins with:
- Jenkins LTS image
- Persistent volume for Jenkins data
- Configuration as Code integration
- Docker-in-Docker capability
- Environment variables for credentials

## Configuration as Code (JCasC)

All Jenkins configuration is stored in YAML files in the `casc_configs` directory:

- **jenkins.yaml**: Core Jenkins configuration (security, tools, UI settings)
- **credentials.yaml**: Credentials for various services and nodes
- **workers.yaml**: Worker node configurations

## Adding Worker Nodes

### Method 1: Using the Helper Script

Run the `add_worker.sh` script and follow the prompts:
```bash
./add_worker.sh
```

### Method 2: Manual Configuration

1. Create or edit `casc_configs/workers.yaml`:
   ```yaml
   jenkins:
     nodes:
       - permanent:
           name: "worker1"
           nodeDescription: "Worker node"
           numExecutors: 2
           remoteFS: "/home/jenkins/agent"
           labelString: "worker linux"
           mode: NORMAL
           launcher:
             ssh:
               host: "worker-ip-address"
               credentialsId: "worker-credentials"
               port: 22
               sshHostKeyVerificationStrategy:
                 manuallyTrustedKeyVerificationStrategy:
                   requireInitialManualTrust: false
   ```

2. Restart Jenkins to apply the configuration:
   ```bash
   docker-compose restart jenkins
   ```

## Setting up a VirtualBox Agent

To set up a Jenkins agent on a VirtualBox VM:

1. Create and set up a VirtualBox VM with Ubuntu
2. Set up port forwarding (Settings > Network > Adapter 1 > Port Forwarding):
   - Protocol: TCP
   - Host IP: 127.0.0.1
   - Host Port: 2222
   - Guest IP: (leave blank)
   - Guest Port: 22

3. Copy the `setup-virtualbox-agent.sh` script to the VM:
   ```bash
   scp -P 2222 setup-virtualbox-agent.sh user@127.0.0.1:~/
   ```

4. SSH into the VM and run the script:
   ```bash
   ssh -p 2222 user@127.0.0.1
   chmod +x setup-virtualbox-agent.sh
   ./setup-virtualbox-agent.sh
   ```

5. Follow the prompts and note the SSH key information

6. Add the node in your Jenkins configuration:
   ```yaml
   credentials:
     system:
       domainCredentials:
         - credentials:
             - basicSSHUserPrivateKey:
                 scope: GLOBAL
                 id: "virtualbox-agent-key"
                 username: "jenkins"
                 privateKeySource:
                   directEntry:
                     privateKey: "-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----"
   
   jenkins:
     nodes:
       - permanent:
           name: "virtualbox-agent"
           nodeDescription: "VirtualBox local agent"
           numExecutors: 1
           remoteFS: "/home/jenkins/jenkins-agent"
           labelString: "virtualbox linux"
           mode: NORMAL
           launcher:
             ssh:
               host: "127.0.0.1"
               credentialsId: "virtualbox-agent-key"
               port: 2222
               sshHostKeyVerificationStrategy:
                 manuallyTrustedKeyVerificationStrategy:
                   requireInitialManualTrust: false
   ```

## Setting up Azure Agents

Azure VM agents are configured in the main `jenkins.yaml` file. The setup script already prompts for Azure credentials.

The configuration includes:
- Azure credentials
- Resource group for agents
- VM templates for agent provisioning
- Initialization scripts for new agents

## Backup and Restore

### Backup

Run the backup script manually:
```bash
./backup_jenkins.sh
```

Or set up a cron job to run it automatically:
```bash
crontab -e
# Add: 0 2 * * * /path/to/backup_jenkins.sh
```

### Restore

To restore Jenkins from a backup:

```bash
# Stop Jenkins
docker-compose down

# Restore the backup (replace with your backup file)
docker run --rm -v jenkins_home:/var/jenkins_home -v /path/to/backups:/backup ubuntu bash -c "cd /var/jenkins_home && tar xzf /backup/jenkins_backup_20250515_120000.tar.gz --strip 1"

# Start Jenkins
docker-compose up -d
```

## Troubleshooting

### Viewing Logs

```bash
docker-compose logs -f jenkins
```

### Restarting Jenkins

```bash
docker-compose restart jenkins
```

### Configuration Reload

To reload the configuration without restarting Jenkins:

```bash
curl -X POST http://localhost:8080/reload-configuration-as-code/ -u admin:password
```

### Common Issues

1. **Permission Issues**: If Jenkins can't access Docker socket, verify permissions:
   ```bash
   sudo chmod 666 /var/run/docker.sock
   ```

2. **Configuration Not Applied**: Check syntax of YAML files and review Jenkins logs

3. **Worker Connection Issues**: Verify SSH keys, port connectivity, and security groups

## Customizing Jenkins

To customize Jenkins further:

1. Edit the files in `casc_configs/`
2. Apply changes by restarting Jenkins or using the reload endpoint
3. For major changes, backup Jenkins first using the backup script

## Security Considerations

- Change the default admin password immediately
- Use secrets management for credentials
- Set up HTTPS with a reverse proxy like Nginx
- Keep Jenkins and plugins updated regularly
- Implement proper backup and disaster recovery procedures