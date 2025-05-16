#!/bin/bash

# Script to back up JCasC configuration files periodically
# Can be added to crontab to run at scheduled intervals

# Set variables
JENKINS_HOME=${JENKINS_HOME:-/var/jenkins_home}
JCASC_DIR="${JENKINS_HOME}/jcasc"
BACKUP_DIR="${JCASC_DIR}/backups"
RETENTION_DAYS=30  # Number of days to keep backups

# Create timestamp
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Backup JCasC configuration files
echo "Backing up JCasC configuration files to ${BACKUP_DIR}/jcasc-${TIMESTAMP}.tar.gz"
tar -czf "${BACKUP_DIR}/jcasc-${TIMESTAMP}.tar.gz" -C "${JENKINS_HOME}" jcasc

# Delete backups older than retention period
find "${BACKUP_DIR}" -name "jcasc-*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete

echo "Backup completed: ${BACKUP_DIR}/jcasc-${TIMESTAMP}.tar.gz"
echo "Deleted backups older than ${RETENTION_DAYS} days"

# List current backups
echo "Current backups:"
ls -lh "${BACKUP_DIR}" | grep "jcasc-"