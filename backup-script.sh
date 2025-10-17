#!/bin/bash

# Variables
SOURCE_DIR="/var/www/html/media"
ARCHIVE_NAME="xfusioncorp_media.zip"
LOCAL_BACKUP_DIR="/backup"
REMOTE_USER="clint"
REMOTE_HOST="stbkp01"
REMOTE_BACKUP_DIR="/backup"

# Create local backup directory if it doesn't exist
mkdir -p "$LOCAL_BACKUP_DIR"

# Remove old archive if exists
rm -f "${LOCAL_BACKUP_DIR}/${ARCHIVE_NAME}"

# Create zip archive
cd /var/www/html/
zip -r "${LOCAL_BACKUP_DIR}/${ARCHIVE_NAME}" media

# Check if archive was created
if [ ! -f "${LOCAL_BACKUP_DIR}/${ARCHIVE_NAME}" ]; then
    echo "ERROR: Failed to create archive"
    exit 1
fi

# Ensure remote backup directory exists
ssh "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p ${REMOTE_BACKUP_DIR}"

# Copy archive to remote backup server
scp "${LOCAL_BACKUP_DIR}/${ARCHIVE_NAME}" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BACKUP_DIR}/"

# Check if copy was successful
if [ $? -eq 0 ]; then
    echo "Backup completed successfully"
    exit 0
else
    echo "ERROR: Failed to copy to backup server"
    exit 1
fi
```

---
